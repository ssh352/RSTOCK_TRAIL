//+------------------------------------------------------------------+
//|                                                   nbar_type1.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#define MAGICNBAR 20150003
//--- input parameters
input int      n;
input int      m;
input bool     up;
input bool     isLong;
extern string logname;
extern int profitPoint = 40;
extern int initalstop = 60;
extern int step = 10;
int count_n = 0 ;
int count_m = 0 ;
bool pre_n = False;
bool ishold =False;
double lot = 0.01;
int slip = 3;
bool New_Bar = False;
int myRetry    = 15;
int myopenedticket = 0;
double stopprice = 0;
bool isModiefiedStop = False;
void Fun_New_Bar()                              
  {                                             
   static datetime New_Time=0;                  
   New_Bar=false;                               
   if(New_Time!=Time[0])                        
     {
      New_Time=Time[0];                         
      New_Bar=True;                                
     }
  }
  
void writeLog(string symbol,double lots,datetime opentime ,double openprice,datetime closetime,double closeprince,double profit)
{
   string ordertype =isLong?"buy":"sell";
   int file_handle=FileOpen(logname,FILE_READ|FILE_WRITE|FILE_CSV);
   if(file_handle!=INVALID_HANDLE)
     {
       FileSeek(file_handle,0,SEEK_END);
       FileWrite(file_handle,ordertype,symbol,lots,opentime,openprice,closetime,closeprince,profit);
       FileClose(file_handle);
     }
     else
     {
      Print("file open erro:",file_handle);
     }
}
void writeLog(string text)
{
    int file_handle=FileOpen(logname,FILE_READ|FILE_WRITE|FILE_CSV);
   if(file_handle!=INVALID_HANDLE)
     {
       FileSeek(file_handle,0,SEEK_END);
       FileWrite(file_handle,text);
       FileClose(file_handle);
     }
     else
     {
      Print("file open erro:",file_handle);
     }
}
void reset()
{
    ishold = False;
    myopenedticket = 0 ;
    count_m = 0;
    stopprice = 0;
    isModiefiedStop = False;
    count_n = 0;
    pre_n = False;
}

void checkIfClosed()
{
  int i,hstTotal=OrdersHistoryTotal();
  for(i=0;i<hstTotal;i++)
    {
     if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
       {
        Print("Access to history failed with error (",GetLastError(),")");
        break;
       }else
       {
         int tk = OrderTicket();
         if(tk == myopenedticket )
         {
            writeLog("stoped");
            writeLog(OrderSymbol(),OrderLots(),OrderOpenTime(),OrderOpenPrice(),OrderCloseTime(),OrderClosePrice(),OrderProfit());
            reset();
         }
       }
     
    }
}

void holdorder()
{
    count_n++;
   if(count_n == n)
   {
      int res= -1 ;
      int ctn_i = -1;
	   int ti = myRetry;
      if(isLong == True)
      {
         while(true){
            double stoploss=NormalizeDouble(Ask-initalstop*Point,Digits);
             res =  OrderSend(Symbol(),OP_BUY,lot,Ask,slip,stoploss,0,"",MAGICNBAR,0,Red);
             if(res > 0 )
             {
                ishold = True;
                myopenedticket = res;
                bool m1 = OrderSelect(myopenedticket,SELECT_BY_TICKET);
                stopprice = OrderOpenPrice() ;
                Print("opened long: ",stopprice);
                break;
             }
     //        Print("open failed");
              ti--;
             if(ti<=0){
               reset();
               break;
             }        
         }  
      } 
      else
      {    
          while(true){
             double stoploss=NormalizeDouble(Bid+initalstop*Point,Digits);
             res =  OrderSend(Symbol(),OP_SELL,lot,Bid,slip,stoploss,0,"",MAGICNBAR,0,Red);
             if(res > 0 )
             {
                ishold = True;
                myopenedticket = res;
                bool m1 = OrderSelect(myopenedticket,SELECT_BY_TICKET);
                stopprice = OrderOpenPrice() ;
                Print("opened short: ",stopprice);
                break;
             }
    //         Print("open failed");
             ti--;
             if(ti<=0) {
               reset();
               break;
             }         
         } 
      }                          
      count_n = 0;
      pre_n = False;
   }
}

//平仓开仓的订单
void clearOrders()
{
    if(myopenedticket == 0 ) return;
     bool res = OrderSelect(myopenedticket,SELECT_BY_TICKET);
     if(res)
     {
         if(OrderType() == OP_BUY){
   		   while(!OrderClose(OrderTicket(),OrderLots(),Bid,slip));
   		}
   	  if(OrderType() == OP_SELL){
   		    while(!OrderClose(OrderTicket(),OrderLots(),Ask,slip));
   		}
   		bool s=OrderSelect(myopenedticket,SELECT_BY_TICKET);
   		writeLog(OrderSymbol(),OrderLots(),OrderOpenTime(),OrderOpenPrice(),OrderCloseTime(),OrderClosePrice(),OrderProfit());
     }
     else
     {
        Alert("we dont select this order:",myopenedticket);
     }  
      reset();
    Print("clear");
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     count_n = 0 ;
     count_m = 0 ;
     pre_n = FALSE;
     ishold = FALSE;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
 //  Print("ask:",Ask);
  // Print("bid:",Bid);
  checkIfClosed();
   if(ishold)
   {
      if(isLong)
      {
         if(isModiefiedStop ==True && Bid < stopprice)
         {
            clearOrders();
         }
         // fix some unkonw bug
         if(stopprice == 0 ) 
         {
             Print("openend but stopprice is 0,reset it now");
             bool s=OrderSelect(myopenedticket,SELECT_BY_TICKET);
             stopprice = OrderOpenPrice(); 
             Print("stopprice is reset to",stopprice);          
         }
        
         double p = (Bid - stopprice) / Point;
         if(p > profitPoint)
         {  
            Print("enter change now stopprice is :",stopprice);
            stopprice = stopprice + (profitPoint-step) * Point;
            isModiefiedStop = True;
            Print("now p is :",p);
            Print("changed and now stopprice is :",stopprice);
         }
      }
      if(!isLong)
      {
         if(isModiefiedStop ==True && Ask > stopprice)
         {
            clearOrders();
         }
          // fix some unkonw bug
         if(stopprice == 0 ) 
         {
             Print("openend but stopprice is 0,reset it now");
             bool s=OrderSelect(myopenedticket,SELECT_BY_TICKET);
             stopprice = OrderOpenPrice(); 
             Print("stopprice is reset to",stopprice);          
         }
        
         double p = ( stopprice - Ask) / Point;
         if(p > profitPoint)
         {  
            Print("enter change now stopprice is :",stopprice);
            stopprice = stopprice - (profitPoint-step) * Point;
            isModiefiedStop = True;
            Print("now p is :",p);
            Print("changed and now stopprice is :",stopprice);
         }
      }
   }
   Fun_New_Bar();
   if(New_Bar == False) { return;} //新bar时去交易
    
   bool uporfall =((Close[1] - Open[1]) > 0)?True:False;//前一个bar涨跌情况
   if(ishold == False) //未持仓
   {
      if(pre_n == False && up == True && uporfall == True)
      {
         pre_n = True;
      }
      if(pre_n == False && up == False && uporfall == False)
      {
         pre_n = True;
      }
      if(pre_n == True && up == True && uporfall ==True)
      {
        holdorder();
      }
      else if(pre_n == True && up == False && uporfall ==False)
      {
          holdorder();
      }
      else
      {
         count_n = 0;
         pre_n = False;
      }
   }
   else // 已经持仓
   {
      count_m++;
      if(count_m == m && isModiefiedStop ==False)
      {
         clearOrders();
         count_m = 0;
      }
   }
  }
//+------------------------------------------------------------------+
