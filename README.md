# CJieba.jl

[CJieba](https://github.com/yanyiwu/cjieba/) word tokenizor and part-of-speech tagging in Julia.

_CJieba is nice and simple and quite adequate for simple tasks specially those prioritize speed over accuracy._


## Usage

```julia
using CJieba
s = "他来到了网易杭研大厦"
```

Tokenize sentence:

```julia
cut(s)
```

Output:

```
6-element Vector{String}:
 "他"
 "来到"
 "了"
 "网易"
 "杭研"
 "大厦"
```

Tokenize and POS tagging:

```julia
tag(s)
```

Output:

```
6-element Vector{Tuple{String, String}}:
 ("他", "r")
 ("来到", "v")
 ("了", "ul")
 ("网易", "n")
 ("杭研", "x")
 ("大厦", "n")
```

Tokenize without tag:

```julia
cut(s; without="x")
```

Output:

```
5-element Vector{String}:
 "他"
 "来到"
 "了"
 "网易"
 "大厦"
```

Manually create handle, add user word, and manually free handle:

```julia
jieba = JIEBA()
add_word!(jieba, "网易杭研大厦")
cut(jieba, s)
tag(jieba, s)
free!(jieba)
```

Output:

```
4-element Vector{String}:
 "他"
 "来到"
 "了"
 "网易杭研大厦"

4-element Vector{Tuple{String, String}}:
 ("他", "r")
 ("来到", "v")
 ("了", "ul")
 ("网易杭研大厦", "u")
```

This works too:

```julia
jieba = JIEBA(; user_words=["网易杭研大厦"])
```

Or pass a file path:

```julia
jieba = JIEBA(; user_words="/path/to/your/user_dict")
```

```do``` syntax (*auto free handle*):

```julia
JIEBA(; user_words=["网易杭研大厦"]) do jieba
   tag(jieba, s)
end
```

## Goals

- Make it idiomatic to use in Julia.
- Make it safe, *mostly (I'm pretty sure some weird ill-formated user_dict can still segfault it...)* 
- Keep it simple (didn't even expose keyword extractor).
