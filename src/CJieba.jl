module CJieba

using CJieba_jll

export JIEBA, add_word!, cut, tag, free!


mutable struct Jieba
    const ptr::Ptr{Cvoid}
    freed::Bool
end


struct CJiebaWord
    word::Cstring
    len::Csize_t
end


function create_jieba(user_words)
    Jieba(
        ccall((:NewJieba, libcjieba),
            Ptr{Cvoid},
            (Cstring, Cstring, Cstring, Cstring, Cstring),
            jieba_dict, hmm_model, user_words, idf, stop_words),
        false
    )
end


function JIEBA(; user_words::Union{String, Vector{String}} = user_dict)::Jieba
    if isa(user_words, String)
        if isfile(user_words)
            create_jieba(user_words)
        else
            throw(ArgumentError("$(user_words) not found."))
        end
    else
        jieba = create_jieba(user_dict)
        for w in user_words add_word!(jieba, w) end
        jieba
    end
end


function JIEBA(f::Function; user_words = user_dict)
    jieba = JIEBA(; user_words = user_words)
    try f(jieba) finally free!(jieba) end
end


function add_word!(jieba::Jieba, word::String)::Bool
    ccall((:JiebaInsertUserWord, libcjieba),
        Cuchar, (Ptr{Cvoid}, Cstring), jieba.ptr, word)
end


function cut(
    jieba::Jieba, s::String; without::Union{String, Nothing} = nothing
)::Vector{String}

    !jieba.freed || throw(ArgumentError("Jieba already freed."))

    ws = without == nothing ?
        ccall((:Cut, libcjieba),
            Ptr{CJiebaWord}, (Ptr{Cvoid}, Cstring, Csize_t),
            jieba.ptr, s, sizeof(s)) :
        ccall((:CutWithoutTagName, libcjieba),
            Ptr{CJiebaWord}, (Ptr{Cvoid}, Cstring, Csize_t, Cstring),
            jieba.ptr, s, sizeof(s), without)

    res, i = Vector{String}(), 1
    while true
        w = unsafe_load(ws, i).word
        if w == C_NULL break end
        push!(res, unsafe_string(pointer(w), unsafe_load(ws, i).len))
        i += 1
    end

    ccall((:FreeWords, libcjieba), Cvoid, (Ptr{CJiebaWord},), ws)

    res
end


function cut(
    s::String; without::Union{String, Nothing} = nothing
)::Vector{String}
    JIEBA() do jieba cut(jieba, s; without = without) end
end


function tag(jieba::Jieba, s::String)::Vector{Tuple{String, String}}
    !jieba.freed || throw(ArgumentError("Jieba already freed."))

    wts = ccall((:CutWithTag, libcjieba),
        Ptr{Cvoid},
        (Ptr{Cvoid}, Cstring, Csize_t),
        jieba.ptr, s, sizeof(s))

    res, p = Vector{Tuple{String, String}}(), wts

    # CJiebaWordWithTag is a C99-compliant variable length struct:
    # https://github.com/yanyiwu/cjieba/blob/1db462d33255aff08802c248b6d6e59202b5619e/lib/jieba.h#L16
    # we directly calculate offsets here as doc suggested.
    while true
        wptr = unsafe_load(Ptr{Cstring}(p))
        if wptr == C_NULL break end
        tptr = p + sizeof(Cstring) + sizeof(Csize_t)
        t = unsafe_string(Ptr{Int8}(tptr))
        len = unsafe_load(Ptr{Csize_t}(p + sizeof(Csize_t)))
        w = unsafe_string(pointer(wptr), len)
        push!(res, (w, t))
        p += sizeof(Cstring) + sizeof(Csize_t) + sizeof(t) + 1
    end

    ccall((:FreeWordTag, libcjieba), Cvoid, (Ptr{Cvoid},), wts)
    res
end


function tag(s::String)::Vector{Tuple{String, String}}
    JIEBA() do jieba tag(jieba, s) end
end


function free!(jieba::Jieba)
    ccall((:FreeJieba, libcjieba), Cvoid, (Ptr{Cvoid},), jieba.ptr)
    jieba.freed = true
end


end # module