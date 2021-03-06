# -*- coding: utf-8 -*-
import numpy as np
import matplotlib
from matplotlib import pylab, mlab, pyplot
plt = pyplot
from IPython.display import display
from IPython.core.pylabtools import figsize, getfigs
from pylab import *
from numpy import *
import pandas as pd
import exceptions
from pandas import DataFrame,Series


## 以上库是在执行ipython --pylab 启动时导入的包
import json
##
plot(arange(10))
#data source
#https://github.com/wesm/pydata-book
dirpath = 'd:/pydata-book/'
path =dirpath + 'ch02/usagov_bitly_data2012-03-16-1331923249.txt'
open(path).readline()
records = [json.loads(line) for line in open(path)]

time_zones = [rec['tz'] for rec in records if 'tz' in rec]

def get_counts(sequence):
    counts= {}
    for x in sequence:
        if x in counts:
            counts[x] += 1
        else :
            counts[x] = 1
    return counts 
#库版本
from collections import defaultdict
def get_counts1(sequence):
    counts = defaultdict(int)
    for x in sequence:
        counts[x] += 1
    return counts

counts = get_counts(time_zones)
#按统计个数排序
def top_counts(count_dict,n=10):
    value_key_pairs = [(count,tz) for tz,count in count_dict.items()]
    value_key_pairs.sort()
    return value_key_pairs[-n:]
top_counts(counts)
from collections import Counter
counts = Counter(time_zones)
counts.most_common(10)

frame = DataFrame(records)
tz_counts = frame['tz'].value_counts()
#填补空值
clean_tz = frame['tz'].fillna('Missing')
clean_tz[clean_tz == ''] = 'Unknown'
tz_counts = clean_tz.value_counts()
tz_counts[:10].plot(kind='barh',rot=0)
results = Series([x.split()[0] for x in frame.a.dropna()])
cframe = frame[frame.a.notnull()]
operating_systerm = np.where(cframe.a.str.contains('Windows'),'Windows','not Windows')
by_tz_oz = cframe.groupby(['tz',operating_systerm])
agg_counts = by_tz_oz.size().unstack().fillna(0)
indexer = agg_counts.sum(1).argsort()
count_subset = agg_counts.take(indexer)[-10:]

#movie lens数据

unames = ['user_id','gender','age','occupation','zip']
path = dirpath + 'ch02/movielens/users.dat'
users = pd.read_table(path,sep='::',header=None,names=unames)
rnames = ['user_id','movie_id','rating','timestamp']
path = dirpath + 'ch02/movielens/ratings.dat'
ratings = pd.read_table(path,sep='::',header=None,names=rnames)
mnames = ['movie_id','title','genres']
path = dirpath + 'ch02/movielens/movies.dat'
movies = pd.read_table(path,sep='::',header=None,names=mnames)
data = pd.merge(pd.merge(ratings,users),movies)
mean_ratings = data.pivot_table('rating',index='title',columns='gender',aggfunc='mean')
ratings_by_title = data.groupby('title').size()
ratings_by_title[:10]
active_titles = ratings_by_title.index[ratings_by_title>250]
mean_ratings = mean_ratings.ix[active_titles]
#女性最喜欢电话
top_female_ratings = mean_ratings.sort_index(by='F',ascending=False)
mean_ratings['diff'] = mean_ratings['M'] - mean_ratings['F']
sorted_by_diff = mean_ratings.sort_index(by = 'diff')
sorted_by_diff[::-1][:15]
rating_std_by_title = data.groupby('title')['rating'].std()
rating_std_by_title = rating_std_by_title.ix[active_titles]
rating_std_by_title.order(ascending=False)[:10]
#全美婴儿姓名
names1880 = pd.read_csv(dirpath + 'ch02/names/yob1880.txt', names=['name', 'sex', 'births'])
names1880.groupby('sex').births.sum()
years = range(1880, 2011)
pieces = []
columns = ['name', 'sex', 'births']
for year in years:
    path = dirpath + 'ch02/names/yob%d.txt' % year
    frame = pd.read_csv(path, names=columns)

    frame['year'] = year
    pieces.append(frame)
names = pd.concat(pieces, ignore_index=True)
total_births = names.pivot_table('births', index='year',
                                 columns='sex', aggfunc=sum)
total_births.tail()
total_births.plot(title='Total births by sex and year')

def add_prop(group):
    # Integer division floors
    births = group.births.astype(float)

    group['prop'] = births / births.sum()
    return group
names = names.groupby(['year', 'sex']).apply(add_prop)
np.allclose(names.groupby(['year', 'sex']).prop.sum(), 1)

def get_top1000(group):
    return group.sort_index(by='births', ascending=False)[:1000]
grouped = names.groupby(['year', 'sex'])
top1000 = grouped.apply(get_top1000)

pieces = []
for year, group in names.groupby(['year', 'sex']):
    pieces.append(group.sort_index(by='births', ascending=False)[:1000])
top1000 = pd.concat(pieces, ignore_index=True)

top1000.index = np.arange(len(top1000))


#numpy

data = randn(2, 3)
data.shape
data.dtype

data1 = [6,7.5,8,0,1]
arr1 = np.array(data1)
data2 = [[1, 2, 3, 4], [5, 6, 7, 8]]
arr2 = np.array(data2)
arr2
arr2.ndim
arr2.shape

np.zeros(10)
np.zeros((3, 6))
np.empty((2, 3, 2))
np.arange(15)
arr1 = np.array([1, 2, 3], dtype=np.float64)
arr2 = np.array([1, 2, 3], dtype=np.int32)
arr1.dtype
arr2.dtype
arr = np.array([1, 2, 3, 4, 5])
arr.dtype
float_arr = arr.astype(np.float64)
float_arr.dtype
arr = np.array([3.7, -1.2, -2.6, 0.5, 12.9, 10.1])
arr
arr.astype(np.int32)
numeric_strings = np.array(['1.25', '-9.6', '42'], dtype=np.string_)
numeric_strings.astype(float)
int_array = np.arange(10)
calibers = np.array([.22, .270, .357, .380, .44, .50], dtype=np.float64)
int_array.astype(calibers.dtype)
empty_uint32 = np.empty(8, dtype='u4')
empty_uint32
#数组计算
arr = np.array([[1., 2., 3.], [4., 5., 6.]])
arr
arr * arr
arr - arr
1 / arr
arr ** 0.5
#高纬
arr2d = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
arr2d[2]
arr2d[0][2]
arr2d[0, 2]
arr3d = np.array([[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [10, 11, 12]]])
arr3d
arr3d[0]
arr3d[1, 0]
old_values = arr3d[0].copy()
arr3d[0] = 42
arr3d
arr3d[0] = old_values
arr3d
arr3d[1, 0]
arr2d[:2]
arr2d[:2, 1:]

arr2d[1, :2]
arr2d[2, :1]
arr2d[:, :1]

#布尔索引
names = np.array(['Bob', 'Joe', 'Will', 'Bob', 'Will', 'Joe', 'Joe'])
data = randn(7, 4)
names
data
names == 'Bob'
data[names == 'Bob']
data[names == 'Bob', 2:]
data[names == 'Bob', 3]

names != 'Bob'
data[-(names == 'Bob')]

mask = (names == 'Bob') | (names == 'Will')
mask
data[mask]

data[names != 'Joe'] = 7
data

# 花式索引

arr = np.empty((8, 4))
for i in range(8):
    arr[i] = i
arr
arr[[4, 3, 0, 6]]
arr[[-3, -5, -7]]

arr = np.arange(32).reshape((8, 4))
arr
arr[[1, 5, 7, 2], [0, 3, 1, 2]]
arr[[1, 5, 7, 2]][:, [0, 3, 1, 2]]
arr[np.ix_([1, 5, 7, 2], [0, 3, 1, 2])]
#转置和对换

arr = np.arange(15).reshape((3, 5))
arr
arr.T

arr = np.random.randn(6, 3)
np.dot(arr.T, arr)


arr = np.arange(16).reshape((2, 2, 4))
arr
arr.transpose((1, 0, 2))
arr.swapaxes(1, 2)

arr = np.arange(10)
np.sqrt(arr)
np.exp(arr)

x = randn(8)
y = randn(8)
x
y
np.maximum(x, y)

arr = randn(7) * 5
np.modf(arr) 

points = np.arange(-5, 5, 0.01) # 1000 equally spaced points
xs, ys = np.meshgrid(points, points)
ys
from matplotlib.pyplot import imshow, title
import matplotlib.pyplot as plt
z = np.sqrt(xs ** 2 + ys ** 2)
z
plt.imshow(z, cmap=plt.cm.gray); plt.colorbar()
plt.title("Image plot of $\sqrt{x^2 + y^2}$ for a grid of values")
plt.draw()
xarr = np.array([1.1, 1.2, 1.3, 1.4, 1.5])
yarr = np.array([2.1, 2.2, 2.3, 2.4, 2.5])
cond = np.array([True, False, True, True, False])
result = [(x if c else y)
          for x, y, c in zip(xarr, yarr, cond)]
result

result = np.where(cond, xarr, yarr)
result


arr = randn(4, 4)
arr
np.where(arr > 0, 2, -2)
np.where(arr > 0, 2, arr) # set only positive values to 2


arr = np.random.randn(5, 4) # normally-distributed data
arr.mean()
np.mean(arr)
arr.sum()
arr.mean(axis=1)
arr.sum(0)

arr = np.array([[0, 1, 2], [3, 4, 5], [6, 7, 8]])
arr.cumsum(0)
arr.cumprod(1)

arr = randn(100)
(arr > 0).sum() # Number of positive values

bools = np.array([False, False, True, False])
bools.any()
bools.all()
#排序
arr = randn(8)
arr
arr.sort()
arr

arr = randn(5, 3)
arr
arr.sort(1)
arr

large_arr = randn(1000)
large_arr.sort()
large_arr[int(0.05 * len(large_arr))] # 5% quantile


names = np.array(['Bob', 'Joe', 'Will', 'Bob', 'Will', 'Joe', 'Joe'])
np.unique(names)
ints = np.array([3, 3, 3, 2, 2, 1, 1, 4, 4])
np.unique(ints)

values = np.array([6, 0, 0, 3, 2, 5, 6])
np.in1d(values, [2, 3, 6])

#读写文件
arr = np.arange(10)
np.save('some_array', arr)
np.load('some_array.npy')
np.savez('array_archive.npz', a=arr, b=arr)
arch = np.load('array_archive.npz')
arch['b']
!rm some_array.npy
!rm array_archive.npz
!cat array_ex.txt
arr = np.loadtxt('array_ex.txt', delimiter=',')
arr
#线性代数
x = np.array([[1., 2., 3.], [4., 5., 6.]])
y = np.array([[6., 23.], [-1, 7], [8, 9]])
x
y
x.dot(y)  # equivalently np.dot(x, y)

np.dot(x, np.ones(3))

np.random.seed(12345)
from numpy.linalg import inv, qr
X = randn(5, 5)
mat = X.T.dot(X)
inv(mat)
mat.dot(inv(mat))
q, r = qr(mat)
r
#随机数生成
samples = np.random.normal(size=(4, 4))
samples
from random import normalvariate
N = 1000000
%timeit samples = [normalvariate(0, 1) for _ in xrange(N)]
%timeit np.random.normal(size=N)
#随机漫步
np.random.seed(12345)
nsteps = 1000
draws = np.random.randint(0, 2, size=nsteps)
steps = np.where(draws > 0, 1, -1)
walk = steps.cumsum()
walk.min()
walk.max()
(np.abs(walk) >= 10).argmax()
#pandas学习

from pandas import Series, DataFrame
import pandas as pd
from __future__ import division
from numpy.random import randn
import numpy as np
import os
import matplotlib.pyplot as plt
np.random.seed(12345)
plt.rc('figure', figsize=(10, 6))
from pandas import Series, DataFrame
import pandas as pd
np.set_printoptions(precision=4)
#相关数据结构
obj = Series([4, 7, -5, 3])
obj

obj.values
obj.index

obj2 = Series([4, 7, -5, 3], index=['d', 'b', 'a', 'c'])
obj2

obj2['a']


obj2['d'] = 6
obj2[['c', 'a', 'd']]

obj2[obj2 > 0]
obj2 * 2

np.exp(obj2)
'b' in obj2

sdata = {'Ohio': 35000, 'Texas': 71000, 'Oregon': 16000, 'Utah': 5000}
obj3 = Series(sdata)
obj3

states = ['California', 'Ohio', 'Oregon', 'Texas']
obj4 = Series(sdata, index=states)
obj4
pd.isnull(obj4)
pd.notnull(obj4)
obj4.isnull()
obj3 + obj4
obj4.name = 'population'
obj4.index.name = 'state'
obj4
obj.index = ['Bob', 'Steve', 'Jeff', 'Ryan']

#dataFrame
data = {'state': ['Ohio', 'Ohio', 'Ohio', 'Nevada', 'Nevada'],
        'year': [2000, 2001, 2002, 2001, 2002],
        'pop': [1.5, 1.7, 3.6, 2.4, 2.9]}
frame = DataFrame(data)
DataFrame(data, columns=['year', 'state', 'pop'])

frame2 = DataFrame(data, columns=['year', 'state', 'pop', 'debt'],
                   index=['one', 'two', 'three', 'four', 'five'])
frame2
frame2['state'] 
frame2.year
frame2.ix['three']
frame2['debt'] = 16.5
frame2

frame2['debt'] = np.arange(5.)
frame2

val = Series([-1.2, -1.5, -1.7], index=['two', 'four', 'five'])
frame2['debt'] = val
frame2

frame2['eastern'] = frame2.state == 'Ohio'
frame2
del frame2['eastern']
frame2.columns

pop = {'Nevada': {2001: 2.4, 2002: 2.9},
       'Ohio': {2000: 1.5, 2001: 1.7, 2002: 3.6}}
       
frame3 = DataFrame(pop)
frame3

frame3.T
DataFrame(pop, index=[2001, 2002, 2003])

pdata = {'Ohio': frame3['Ohio'][:-1],
         'Nevada': frame3['Nevada'][:2]}
DataFrame(pdata)

frame3.index.name = 'year'; frame3.columns.name = 'state'
frame3
frame3.values

obj = Series(range(3), index=['a', 'b', 'c'])
index = obj.index
index
index[1:]
index = pd.Index(np.arange(3))
obj2 = Series([1.5, -2.5, 0], index=index)
obj2.index is index

'Ohio' in frame3.columns
2003 in frame3.index
#基本功能
#重新索引
obj = Series([4.5, 7.2, -5.3, 3.6], index=['d', 'b', 'a', 'c'])
obj
obj2 = obj.reindex(['a', 'b', 'c', 'd', 'e'])
obj2
obj.reindex(['a', 'b', 'c', 'd', 'e'], fill_value=0)

obj3 = Series(['blue', 'purple', 'yellow'], index=[0, 2, 4])
obj3.reindex(range(6), method='ffill')

frame = DataFrame(np.arange(9).reshape((3, 3)), index=['a', 'c', 'd'],
                  columns=['Ohio', 'Texas', 'California'])
frame
#重新索引行
frame2 = frame.reindex(['a', 'b', 'c', 'd'])
frame2
#重新索引列
states = ['Texas', 'Utah', 'California']
frame.reindex(columns=states)
frame.reindex(index=['a', 'b', 'c', 'd'], method='ffill',
              columns=states)
frame.ix[['a', 'b', 'c', 'd'], states]    

#Dropping entries from an axis
obj = Series(np.arange(5.), index=['a', 'b', 'c', 'd', 'e'])
new_obj = obj.drop('c')
new_obj

obj.drop(['d', 'c'])
data = DataFrame(np.arange(16).reshape((4, 4)),
                 index=['Ohio', 'Colorado', 'Utah', 'New York'],
                 columns=['one', 'two', 'three', 'four'])
data.drop(['Colorado', 'Ohio'])
data.drop('two', axis=1)
data.drop(['two', 'four'], axis=1)
#索引、选择、过滤
obj = Series(np.arange(4.), index=['a', 'b', 'c', 'd'])
obj['b']
obj[1]
obj[2:4]
obj[['b', 'a', 'd']]
obj[[1, 3]]
obj[obj < 2]
obj['b':'c']
obj['b':'c'] = 5

data = DataFrame(np.arange(16).reshape((4, 4)),
                 index=['Ohio', 'Colorado', 'Utah', 'New York'],
                 columns=['one', 'two', 'three', 'four'])
data['two']
data[['three', 'one']]
data[:2]
data[data['three'] > 5]
data < 5
data[data < 5] = 0
data
data.ix['Colorado', ['two', 'three']]
data.ix[['Colorado', 'Utah'], [3, 0, 1]]
data.ix[2]
data.ix[:'Utah', 'two']
data.ix[data.three > 5, :3]
#算术运算和数据对齐
s1 = Series([7.3, -2.5, 3.4, 1.5], index=['a', 'c', 'd', 'e'])
s2 = Series([-2.1, 3.6, -1.5, 4, 3.1], index=['a', 'c', 'e', 'f', 'g'])
s1+s2
df1 = DataFrame(np.arange(9.).reshape((3, 3)), columns=list('bcd'),
                index=['Ohio', 'Texas', 'Colorado'])
df2 = DataFrame(np.arange(12.).reshape((4, 3)), columns=list('bde'),
                index=['Utah', 'Ohio', 'Texas', 'Oregon'])
df1 + df2
df1.add(df2, fill_value=0)
df1.reindex(columns=df2.columns, fill_value=0)
#基本计算
arr = np.arange(12.).reshape((3, 4))
arr
arr[0]
arr - arr[0]

frame = DataFrame(np.arange(12.).reshape((4, 3)), columns=list('bde'),
                  index=['Utah', 'Ohio', 'Texas', 'Oregon'])
series = frame.ix[0]
frame
frame - series
series2 = Series(range(3), index=['b', 'e', 'f'])
frame + series2
series3 = frame['d']
frame.sub(series3, axis=0)

#函数映射
frame = DataFrame(np.random.randn(4, 3), columns=list('bde'),
                  index=['Utah', 'Ohio', 'Texas', 'Oregon'])
np.abs(frame)

f = lambda x: x.max() - x.min()
frame.apply(f)
frame.apply(f, axis=1)
def f(x):
    return Series([x.min(), x.max()], index=['min', 'max'])
frame.apply(f)
format = lambda x: '%.2f' % x
frame.applymap(format)
frame['e'].map(format)
#排序排名
obj = Series(range(4), index=['d', 'a', 'b', 'c'])
obj.sort_index()

frame = DataFrame(np.arange(8).reshape((2, 4)), index=['three', 'one'],
                  columns=['d', 'a', 'b', 'c'])
frame.sort_index()
frame.sort_index(axis=1)
frame.sort_index(axis=1, ascending=False)

obj = Series([4, 7, -3, 2])
obj.order()

obj = Series([4, np.nan, 7, np.nan, -3, 2])
obj.order()

frame = DataFrame({'b': [4, 7, -3, 2], 'a': [0, 1, 0, 1]})
frame
frame.sort_index(by='b')
frame.sort_index(by=['a', 'b'])

obj = Series([7, -5, 7, 4, 2, 0, 4])
obj.rank()
obj.rank(method='first')
obj.rank(ascending=False, method='max')
frame = DataFrame({'b': [4.3, 7, -3, 2], 'a': [0, 1, 0, 1],
                   'c': [-2, 5, 8, -2.5]})
frame.rank(axis=1)
#重复索引
obj = Series(range(5), index=['a', 'a', 'b', 'b', 'c'])
obj
obj.index.is_unique
obj['a']
obj['c']
df = DataFrame(np.random.randn(4, 3), index=['a', 'a', 'b', 'b'])
df
df.ix['b']
#基本描述统计
df = DataFrame([[1.4, np.nan], [7.1, -4.5],
                [np.nan, np.nan], [0.75, -1.3]],
               index=['a', 'b', 'c', 'd'],
               columns=['one', 'two'])
df.sum()
df.sum(axis=1)
df.mean(axis=1, skipna=False)
df.idxmax()
df.cumsum()

df.describe()
obj = Series(['a', 'a', 'b', 'c'] * 4)
obj.describe()

#相关系数
import pandas.io.data as web

all_data = {}
for ticker in ['AAPL', 'IBM', 'MSFT', 'GOOG']:
    all_data[ticker] = web.get_data_yahoo(ticker)

price = DataFrame({tic: data['Adj Close']
                   for tic, data in all_data.iteritems()})
volume = DataFrame({tic: data['Volume']
                    for tic, data in all_data.iteritems()})

returns = price.pct_change()
returns.tail()

returns.MSFT.corr(returns.IBM)
returns.MSFT.cov(returns.IBM)
returns.corr()
returns.cov()
returns.corrwith(returns.IBM)
returns.corrwith(volume)

#唯一值
obj = Series(['c', 'a', 'd', 'a', 'a', 'b', 'b', 'c', 'c'])
uniques = obj.unique()
obj.value_counts()
pd.value_counts(obj.values, sort=False)
mask = obj.isin(['b', 'c'])
mask
obj[mask]

data = DataFrame({'Qu1': [1, 3, 4, 3, 4],
                  'Qu2': [2, 3, 1, 2, 3],
                  'Qu3': [1, 5, 2, 4, 4]})
data

result = data.apply(pd.value_counts).fillna(0)
result

string_data = Series(['aardvark', 'artichoke', np.nan, 'avocado'])
string_data

#缺失数据
string_data = Series(['aardvark', 'artichoke', np.nan, 'avocado'])
string_data
string_data.isnull()
string_data[0] = None
string_data.isnull()
from numpy import nan as NA
data = Series([1, NA, 3.5, NA, 7])
data.dropna()
data[data.notnull()]
data = DataFrame([[1., 6.5, 3.], [1., NA, NA],
                  [NA, NA, NA], [NA, 6.5, 3.]])
cleaned = data.dropna()
datadata.dropna(how='all')
data[4] = NA
data
data.dropna(axis=1, how='all')
df = DataFrame(np.random.randn(7, 3))
df.ix[:4, 1] = NA; df.ix[:2, 2] = NA
df
df.dropna(thresh=3)
df.fillna(0)
In [ ]:
df.fillna({1: 0.5, 3: -1})
In [ ]:
df.fillna(0)
df.fillna({1: 0.5, 3: -1})
# always returns a reference to the filled object
_ = df.fillna(0, inplace=True)
df = DataFrame(np.random.randn(6, 3))
df.ix[2:, 1] = NA; df.ix[4:, 2] = NA
df
df.fillna(method='ffill')
df.fillna(method='ffill', limit=2)
data = Series([1., NA, 3.5, NA, 7])
data.fillna(data.mean())
#层次化索引
data = Series(np.random.randn(10),
              index=[['a', 'a', 'a', 'b', 'b', 'b', 'c', 'c', 'd', 'd'],
                     [1, 2, 3, 1, 2, 3, 1, 2, 2, 3]])
data
data.index
data['b']
data[['b','d']]
data.ix[['b', 'd']]
data[:, 2]

data.unstack()
frame = DataFrame(np.arange(12).reshape((4, 3)),
                  index=[['a', 'a', 'b', 'b'], [1, 2, 1, 2]],
                  columns=[['Ohio', 'Ohio', 'Colorado'],
                           ['Green', 'Red', 'Green']])
frame

frame.index.names = ['key1', 'key2']
frame.columns.names = ['state', 'color']
frame
frame['Ohio']
frame['Colorado']

#reshape data
#时间序列
