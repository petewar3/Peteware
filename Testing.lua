local original_debug = debug

local modified_debug = setmetatable({}, {
    __index = function(_, key)
        if key == "getinfo" then
            return function(...)
                local result = original_debug.getinfo(...)

                if typeof(result.func) == "function" and result.currentline ~= -1 then
                    result.what = "C"
                    result.source = "=[C]"
                    result.short_src = "[C]"
                    result.currentline = -1
                    result.linedefined = -1
                    result.name = "new_cclosure_handler"
                end

                return result
            end
        end

        return original_debug[key]
    end
})

debug = modified_debug

local opcodes = {
    -- Standard Ops (<18)
    [0]  = "CLEAR_RANGE",
    [1]  = "ADD",
    [2]  = "GETTABUP",
    [3]  = "MOVE",
    [4]  = "LOADK",
    [5]  = "TGETR",
    [6]  = "SUB",
    [7]  = "GETTABLE",
    [8]  = "NUMERIC_FOR_LOOP",
    [9]  = "SETCONST",
    [10] = "MUL",
    [11] = "CALL_MULTIRETURN",
    [12] = "SETTABUP",
    [13] = "LOADK",
    [14] = "CALL_RETURN",
    [15] = "SETTABLE",
    [16] = "DIV",
    [17] = "NEWTABLE",

    -- Extended Ops (>18)
    [19] = "LEN",
    [20] = "MOD",
    [21] = "CONCAT",
    [22] = "EQ",
    [23] = "LT",
    [24] = "LE",
    [25] = "JMP_EQ",          
    [26] = "JMP_LT",   
    [27] = "POW",
    [28] = "NOT",
    [29] = "TESTSET",
    [30] = "CALL",
    [31] = "CLOSURE",
    [32] = "UNM",
    [33] = "TESTSET_VARIANT",
    [34] = "FORPREP",
    [35] = "FORLOOP",
    [36] = "TFORLOOP",
    [37] = "UNKNOWN"
}

getfenv(0).DumpTable = function(tbl, translate_opcodes, indent, visited)
    translate_opcodes = translate_opcodes or false
    indent = indent or 0
    visited = visited or {}

    if visited[tbl] then
        warn(string.rep(" ", indent) .. "*CYCLE*")
        return
    end
    visited[tbl] = true

    for k, v in pairs(tbl) do
        local prefix = string.rep(" ", indent)
        local key_str = "[" .. tostring(k) .. "]"
        local value_str

        if typeof(v) == "table" then
            warn(prefix .. key_str .. " = {")
            getfenv(0).DumpTable(v, translate_opcodes, indent + 4, visited)
            warn(prefix .. "}")
        else
            if translate_opcodes and k == "op" and type(v) == "number" then
                value_str = opcodes[v] or ("UNKNOWN_OP_" .. v)
            else
                value_str = tostring(v)
            end
            warn(prefix .. key_str .. " = " .. value_str)
        end
    end
    
    return tbl
end

getfenv(0).FindConstant = function(tbl, key, registry, const_counter)
    registry = registry or 0
    const_counter = const_counter or 0

    for i, v in pairs(tbl) do
        local current_registry = registry
        if type(i) == "number" then
            current_registry = i
        end

        if i == "const" and v == key then
            const_counter = const_counter + 1
            warn(string.format("LOADK R%d K%d", current_registry, const_counter))
        elseif type(v) == "table" then
            const_counter = getfenv(0).FindConstant(v, key, current_registry, const_counter)
        end
    end

    return const_counter
end

getfenv(0).ReplaceConstant = function(tbl, key, value, registry, const_counter)
    registry = registry or 0
    const_counter = const_counter or 0

    for i, v in pairs(tbl) do
        local current_registry = registry
        if typeof(i) == "number" then
            current_registry = i
        end

        if i == "const" and v == key then
            tbl[i] = value
            const_counter = const_counter + 1
            warn(string.format("SETCONST R%d K%d", current_registry, const_counter))
        elseif typeof(v) == "table" then
            const_counter = getfenv(0).ReplaceConstant(v, key, value, current_registry, const_counter)
        end
    end

    return const_counter
end

return ((function(...)
    local d, e, V = table, string, bit;
    local a, N, c, W, M, L, Y, _, X, n, A = e.byte, e.char, e.sub, d.concat, d.insert, math.ldexp, getfenv and getfenv() or _ENV, setmetatable, select, unpack or d.unpack, tonumber;
    local C = ((function(B)
        local e, V, l, A, o, a, n = 1, function(l)
            local e = "";
            for A = 1, #l, 1 do
                e = e .. N(a(l, A) - (10)); 
            end;
            return A(e, 36); 
        end, "", "", {}, 256, {};
        for e = 0, a - 1 do
            n[e] = N(e); 
        end;
        local function C()
            local l = V(c(B, e, e));
            e = e + 1;
            local A = V(c(B, e, e + l - 1));
            e = e + l;
            return A; 
        end;
        l = N(C());
        o[1] = l;
        while e < #B do -- ran 10964 times
            local e = C();
            if n[e] then
                A = n[e];
            else
                A = l .. c(l, 1, 1); 
            end;
            n[a] = l .. c(A, 1, 1);
            o[#o + 1], l, a = A,A,a + 1; 
        end;
        return d.concat(o); 
    end))("<;X<@=<A?<@:<@A<A?<@=<?B<?@<?<<?K<@:<?`<AC<><<>Y<>A<?:<?@<?L<?K<?L<@:<@?<AC<AU<AW<AY<AA<AC<=a<?@<>c<>`<Aa<A?<>`<?@<>Y<>a<B<<@=<>]<Ad<>`<AC<BN<;A<@M<@:<@><AC<?B<?K<>`<BU<?;<>^<A[<AC<>Y<>d<?@<>Z<A`<AQ<A?<?><?=<?:<?;<?K<B`<?C<@:<?c<AC<Bd<C;<?K<?C<>_<?;<?><>`<>c<C;<BR<AC<=d<?:<?:<?=<??<?:<>T<@:<?_<AC<>O<>T<?K<?><>_<CQ<?;<?B<@:<?^<AC<>M<BV<=]<C=<>^<>c<?><AO<K><A?<=]<B><>Z<>`<C=<>M<>_<>c<CT<KP<BV<>B<?:<B`<@:<?X<AC<KB<?;<?L<>?<?:<CQ<?C<KL<?@<CQ<CS<@@<CU<B:<?=<AO<AB<A?<=d<?K<>T<B;<?S<AC<>K<?=<B`<AW<>S<@d<A^<?L<>c<K;<@^<@d<=`<LL<B?<?K<@d<Ac<B:<@c<BB<><<?><CS<?T<AC<>Z<??<>T<B?<>Y<BV<>c<?L<@C<@]<@]<@S<@T<@L<@T<@W<@R<@R<@X<@R<MW<@Q<@W<MW<AP<AC<>P<>_<>Z<L?<CR<?;<BN<AC<?d<>L<@<<@<<@:<@Z<N:<?K<>^<?K<C:<>\\<C=<>Y<@d<CV<CX<CZ<>T<L[<AV<L]<K;<@c<La<Lc<MP<@d<BK<B:<@^<O=<Md<A?<><<?;<>Y<B><CO<AO<@:<AC<C<<>]<C@<AC<>C<L^<?L<?@<??<LL<>O<NR<?;<B;<?b<C_<>Z<>Z<K]<=]<?><>d<AY<>_<LL<?L<@;<@:<LB<A?<OZ<?K<O\\<KY<@=<K\\<?;<C<<CP<K=<AC<C:<AW<OC<>Z<L^<K<<A\\<B=<>S<NU<?:<C?<Bb<@=<CM<CO<L@<?;<O?<@=<=`<BV<?K<BK<K^<Pa<@]<NY<CY<C[<PM<@]<>K<>Y<MP<>`<>Y<QO<>K<>_<L]<?:<QU<BS<A?<@]<><<?<<?@<BU<QU<O^<Q]<??<NS<?=<@_<PX<L_<>\\<K;<@:<Qd<@=<@]<R;<?=<R=<R?<?B<@^<?<<>\\<@Q<@:<>@<AC<>d<>`<>`<>\\<>Y<MT<@]<N=<>]<@^<?B<B:<>d<>_<??<>_<MP<>Z<MA<O\\<PK<>`<@^<MA<?<<@]<NU<KT<QA<@Q<@]<>P<NQ<NS<?:<NU<>Z<@_<QL<N[<R`<CL<>Y<@]<P:<PV<@]<Q`<L^<@]<@:<?a<C_<LR<N=<>N<CN<CP<N?<S`<Q<<>C<?@<?><>a<>_<R]<T<<Q\\<@=<QQ<QS<TM<TV<QW<QY<TZ<AR<Q`<Qb<T<<RK<>d<CW<>a<AN<B><U<<Td<AZ<?]<CB<P:<TQ<?><?@<RO<C=<K_<BT<BV<UL<RO<PY<>Y<?><PX<>\\<B;<CA<A?<=a<>c<>R<B_<?L<@_<TO<TQ<TS<C]<AC<RN<RP<PY<BB<>N<>c<K^<PA<@=<>\\<Ad<>Z<QU<VK<>\\<US<?=<BB<?B<>Y<S<<PM<Ub<TP<TR<>\\<ON<AC<B[<A?<>c<>Y<L=<LL<@:<@<<AC<T<<LN<@=<RS<RU<BB<@^<RA<K<<UA<A?<OP<?><CC<VW<K^<RK<BU<>`<Cc<OC<?:<Q`<QR<BV<@:<WN<AK<BV<>Y<>S<?;<MO<W]<KO<@=<Q`<>a<CL<CX<AX<>Z<Q<<Vb<?C<XA<UO<C^<A?<>]<PX<KT<Vd<AO<Pa<LX<?L<XU<PM<AX<?=<XZ<V^<@=<Wb<Q;<TV<B`<>[<>_<?K<OC<BB<RZ<R\\<@:<?d<RY<R[<>\\<=Y<Xd<Y;<Y=<P[<Pb<?=<>_<>T<S><@:<?W<AC<Y:<?K<Y;<=Y<C;<=Y<KT<LL<>\\<K]<B;<YB<A?<QS<Bd<>c<>\\<CZ<U`<V;<A?<>B<?=<Z><Z@<>Z<AZ<X_<QS<@:<?U<AC<L=<B`<>\\<Oa<>T<>c<?<<B:<P]<Oa<RT<Yd<RY<U:<Pc<TK<CS<K`<Va<AX<O\\<>c<?C<>S<LQ<Cb<Cd<K]<UP<A?<WV<>`<>d<XX<SA<KT<LR<PS<A?<ZV<Y<<>c<?B<Wd<VT<YX<[O<BV<Wd<AN<VS<U><?:<AZ<TV<Lb<?@<[B<VO<W^<A]<?:<US<\\><\\@<PM<K\\<B`<KV<KX<T><LO<NS<?K<Yb<KS<KB<>Z<KK<KM<\\B<A?<>=<YK<\\Z<\\\\<AO<[<<@=<=c<S?<OA<>\\<Cd<\\b<KL<AO<Z:<@=<=]<?:<CN<?L<]A<\\]<YQ<Z><VN<Qc<AC<VA<Kc<VA<VO<>`<>B<>d<>c<?=<AZ<U[<@=<U]<U_<ZO<>A<>c<??<N=<>Z<>S<PM<SU<PW<?:<^A<VK<]M<]O<BB<>?<AM<AO<?\\<AC<Q><SQ<B_<?K<L:<L<<L><Q:<PM<^O<Kc<><<AZ<?Y<MK<MM<X:<CQ<MS<MU<@R<@W<@T<@R<@Q<@V<@L<@S<@K<@S<V`<@=<=b<CX<>_<AN<[W<TW<S@<]^<>^<OW<LL<W<<_Q<^[<[@<^A<?N<CU<CW<QM<N\\<PU<N_<?B<@d<UL<OL<UN<?L<@^<NA<`M<NA<=W<>L<_Q<PW<V?<YQ<XM<>Z<Q`<B;<=_<AC<=W<]N<>Z<@d<[C<Cc<>`<K]<@d<Vb<@d<A<<@^<@T<?C<A<<A<<`@<WZ<VM<CQ<OX<?K<L`<LV<?=<@d<`b<NZ<C[<@d<?C<?K<L?<N<<Y<<@d<B]<]N<]`<O:<K]<>a<@d<B?<`_<>T<NU<CP<AY<`L<`M<?X<`Q<?><`[<`]<b:<[K<`b<`^<a:<a<<a><a@<aB<RT<N><aM<L`<]M<AN<aR<`:<N[<aV<aX<>`<aZ<NW<Q`<LZ<?;<L;<@d<R;<bU<aK<^=<LL<O:<S:<aR<]^<NW<``<[L<>Z<@^<@:<<S<Ka<WZ<M:<aK<Od<_\\<M:<cO<bO<aV<TC<Q:<NW<^Y<@d<Z\\<QR<PY<L`<=a<a^<?L<@d<>S<]N<@d<ZL<X?<b\\<@d<cX<>d<cL<?K<?<<aV<`c<R;<R[<C=<a\\<UW<Z><>`<c?<bW<]_<Z]<ac<UW<QZ<NW<L;<P:<`^<UV<UX<QT<BQ<TV<>C<Cd<`b<?;<_P<X_<=W<Y<<PM=;:B<R[<C;<@R<@:<@;<AC<L:<`N<A=<`Q<Pa<>B<UM<CY<V[<T=<AC<>:<?K<>S<ZN<?L<>O<Wd<aM<AZ<]K<>@<]N<MP=;;><cZ<AZ=;:W<A?<=`<>B<_Q=;;C<??<]_<AO<_c<Q]<S?<NR<SZ<Td<>\\<@_<OV<B><@_<KT<RT<@^<>b<>Y<CS=;;P<@=<QZ<BB=;;a<OM<AC<@c<@Z<B;<W?<Td<N<<_W<>;<=]<>><>?<SU<MA<AX<P@<AC<B><aM=;<S=;<U<>?=;;>=;<Y<LM<C_<?;<_U<OR<\\U<Ya<Yc<KQ<L?<AO<TV=;=A<KS<A`<X<<OA<=`<Oa<?B<B`<QR<[N<]c<BL<PY<>N<Ob<KC<UO<\\T<@=<=_<Y;<Y;<>><?;<LP=;=?<KS<_W=;=c=;>:<\\W<Yc<@:<=Y<AR<CO<aC<bW<cB<C`<>\\<C:<O<<@d<`\\<N<<b:=;>Q<?:<B:<@d<?L<?:<a[<c;<d\\<VW<>\\<\\X<d\\<c\\<M:<C;<aR<\\V=;>c<@d<@\\<cd<>Y<PY<@d<YZ<Y;<Y`=;>@<KS<@[=;<[<Bc<C:<TQ<Q<<OA<>`<=b<UM<Y;=;?S<_R=;?[<AO<W_<KQ<RQ=;?Z<YS<AO<XP<@=<>C<`:=;?d=;?\\<W_<>?<_U<R;<>Z=;@@=;?`<AC<K\\<C:<>Z<@Q=;@N<YA<AC<=b<Cb<bO=;@T=;?_<\\^<PN<>N<N=<AN=;@U<W_<>><??<>b=;@Y=;@U<W?<=`<B_<Za<LO<N=<OB<VM<B`<CO<^M<AC=;;C<X\\<_Q=;A?=;AM<O]<AC<=c<?;<N?<>><SY<N><LA<NP<US<PM<LP<LR<aZ<Q<<>=<_U<?@<c;<MR=;@]<>P<Vb=;>Q<\\?<^R<_V<W?<QL=;Aa<`:<=d<Z><ZB<TW=;AY<`X<N?=;@]<>K=;BV=;A]<?;<^b<RC<LU=;B[<Q:<=d<N==;?V=;=^=;AT<CQ<Bd<?K<>O<Z\\<dW<XC<TV=;;M=;;@<QV<?L=;>\\<OB<_Q<L^<S?<B;=;=^<L:<@d<>K=;CO<C;<NW=;=Z<^P<?Z<^V<ZY<Z[<Z]=;=Q<aC<>`<]Q=;<d<A?<>:<KL<BA<TV<=Y<=Y<OU<LQ<_W=;KC<[b<Cb=;:_=;@]<K@<>`<\\><>`<`V<?<<Q<=;KV=;KX<@:<X_<>><=]<=X=;?]<>@<TP=;K_<PM=;AX<>a<c;<>]<Q;<YQ<]d<ZA=;@<<>?<Q@<U]<Kc<?:<OQ=;C_<A?<SU<>^<NX<b]<aU<>X<La<Q?<QA<KN=;:X<Q@<KB<[:<Q;<VK<QL<QU<]K<>B<LX<KT=;:R=;:K=;B_<O@<?;<L==;AY<KT=;>T<>c<NS<AZ<X<<=^<dR<L;<M:<=]<>\\<^A<]K<SU<N\\=;>P=;@R<XO<AC<>=<>S<?L=;Ca=;<Z<Pa=;:d<U=<L^<\\d=;>K<OC=;B=<KM<@d<Oc=;B=<C<<XC<?M<]W<UR<dP<aP=;CX<_[<]_<cZ<@d<ZK<X:<QU<]b=;M<<b`<?K=;Ab<>`<N[=;==<]L<`A<c=<LZ=;NZ=;=U<YQ=;CY=;CP<QU<[_<@=<]><Cd=;NK<dZ<UY<@d=;BL<]C=;>K<]?<d\\<Oc=;:><_W<=]<?@<NR=;CX=;CZ<Q;<RK=;N^=;=B<>P<Oa<>\\=;>\\=;L?=;@V<KZ<LL<CP=;O^=;CP<ZS<\\C<AW=;NK<\\V<b=<d?=;OA<CS<?[<NP<LL=;MM<KB=;P@<KT=;PQ=;O_=;?]<>><[Q<UO=;M;=;M==;N`<?:<?B<?B<W:=;=^<OA=;NA<O\\<La<Z_<UY<QU<]:<ZK=;MO=;Q@=;BZ<CQ<@_=;K?=;?V<ZT<A?<_`<L=<UL<Q:=;NK<]N<Kc<QU=;@<<PO<B>=;N><XC<?O<NP<>^<S\\<C[<>X<^W<Q@<^Y=;LN=;P<<BB=;@><?L=;MY<AC=;P^=;:;=;L`<^^<?R=;:X<L;<[@<^]<N?<^`<?L<>Y<CV=;Q:<LL<>=<XN<XC<]:=;R]=;Q;<?K<Uc<>a=;=S=;Q\\=;;A<_d=;R^=;S;=;:C<CS=;OK<Q_<Qa=;N`=;AC<>Y=;AL<PK<?><^A<W_<>N<=`<=]<@d=;@><QZ<KT<XC<]b<C`<bN<`c<OA<XM<_Q=;MS<>b=;>Y<Q;<X<<\\b<dX=;R`<V]<]K<C`=;>Z=;R<<C\\=;MZ=;BB<?=<\\?<>><ZO<C=<`M<<L;Y<`Q=;M;<]^<]`=;MS<?<<?:<NR<?L<@A<PA<?V<<[<AC<W<<A?<L[<NA=;;P<^U<A?=;:W=;:W<@?<>W<AC<CA<W<<W<<@A;K=;UP<@=<W<=;U;=;U=<AC<@d<^d<BN<ON<@d<`M<W?<AC=;:W=;UX<BN<VK=;U`<NA<A\\<?V<A?<W<<TV=;UA=;UW<@==;UY<A?<Pa<@=<=\\=;UZ=;UM<@T<AC=;V@=;U><@==;UT=;VV=;VL=;VZ<A?<ZT=;UX=;U<<A?=;@<=;UY<W<<X<=;UN=;VL<^d=;UR=;VY=;UU<A?=;W>=;W@<AC<LT=;V`=;VL<W_=;UY=;:W<X<<@=<^U<W<=;UL<@=<@?=;VU<W<=;WM<AC=;V]<@==;W\\=;W^=;RT=;WV<LB=;VX=;U?<;P<@==;<?<YB=;WY=;X=<@=<@V=;VL<A?=;W^=;XC<W<<@d=;X<=;X><@==;XP=;XA=;:W<CA=;W<=;:W<A;=;VL=;US=;WA<@==;XZ=;X\\<AC=;XN<A?<@U=;XA=;VX<?V<=R<@=<ON=;VX=;V=<ON<ON<O^=;V@<@=<LB=;=^<V_=;YM<`M=;<?=;:W=;V==;WW<K`=;YL<AB=;OK<AC<VK<AB=;VU=;YQ=;V@<YB=;Y^<LB<ZT<^U<@T=;RT<LB=;PT=;C_=;Z;=;YQ<^d<?P<A?<A\\=;:W<VK<@=<<V=;XA<BN=;W^<>==;XK<>V=;ZQ<AC<?X<>c<NB=;XA=;YU=;Z[=;Y^=;XV<@==;Qd=;Uc=;XK=;VM<A@=;Zd=;YA=;Y><@==;YK<A?=;YN<`M<ON=;ZN=;UK=;Zc=;Z]=;:W=;YW<@[=;VY<@==;YZ<>]=;YQ=;XL<@==;Yb=;[:=;Ya=;[A<@=<ZT<_c=;[Z=;Z>=;[Y=;[]=;ZB<BN=;ZM=;XK<<U=;ZW<AC<=:=;[><BN=;YX<@==;NP=;U?=;[X<AB<MC=;YL<LB<LT<NA<AB=;WW=;V=<VK<YB=;\\X=;YQ=;RT=;XZ=;YQ<=[=;VL<?Q=;WK<A?=;\\`=;XO=;X<=;\\Y=;[Y=;Z<<@==;RT=;Qd=;XT<LB<AB=;U`=;U@<LB<LB<@c=;WX<@b<@=<BS=;W?<PA=;@<=;Ub=;@<<NA=;@<=;<?<@==;@<<X_=;]^=;UZ<AC<<C=;YQ=;]U=;]R=;YQ=;Ud=;XK=;@<=;Y;=;U<<A\\=;]S=;ZK=;VU<A\\<?B=;Zd=;W^=;^O=;WN<A\\<@a=;VV=;U<<BS=;^K<A?<^U=;ZL=;XA<A;<;a=;WX<@=<>b=;VL<A==;\\c=;^a=;XK=;Xd<A\\=;ZN;[=;^`=;X:=;ZP<YQ<A?<?V=;[R<A\\<A<<BN<?<=;]T=;^`=;_L=;VO=;X^<`M<BS<BS=;VP<AQ<TV=;YL<C^<A:<`M<AQ<AQ=;]Z<C^<Pa=;YL<K><@\\<`M<C^<C^=;WS<K>=;`;=;[R<UA=;[R<AC;?<@=<K><K><W_<@=<UA<X<=;YL<YB<NO<NA<UA<UA<]K<@=<YB=;Vc<A?<CA<@Y<`M<YB<YB<CA=;YL<CA<@`<`M<O^<]b=;YL<T><@_<BN<RX<O^<O^<\\T=;_R<T>=;aC<A?<K`<b?<BN<T><T><]:<@=<K`=;aU=;[T<RL<b@=;a]=;a`<AC<YX<]:=;YL=;V@=;Y^<BN<YX<YX=;YL=;_U=;b<=;[R<ZT<@S=;aN=;[:=;V@=;QU<?C=;[^=;[S=;_U=;WT=;`U=;V[<@==;PT<@R=;bZ=;C_<@Q=;bZ<^d<@X<`M<ZT=;WC<@==;ZV=;WU=;VV=;[R=;PT<@W<BN<=B=;bX=;PT=;U>=;ZV=;cM=;c?<@==;C_=;XC<AC=;cK=;[b=;cN=;cR=;Zd=;_M<@=<^d=;cT<A?=;cK=;C_=;c;=;ZV=;U]<BN<bC=;ZC<`N=;Zb<`M=;;Y=;YR=;[<<A?=;NP<AB=;Xd<AC=;NP=;^>=;YL=;NP<@L<`M<MC=;QU<BN=;dO=;W_=;bV<A?<<Z=;XK=;\\`=;V=<@==;\\b=;X@=;U`<=>=;^P=;X]=;dd=;X`<A?=;U<=;WN=;U`<@K<AC<@?=;]S=;]Q=;Y?=;ZQ=;@<<RK=;]a<A?=;\\b=;:c=;XS=;XA=;]Q=;W<=;U`<<a=;X[=;_:=<:[=<:=<@=<=;=;VL=;X@=;]Q=<:a=;VX=;W^=<;:=;_:<<\\=;\\==;\\?<A?<;T=;]b<PB=;c\\=;d`<@==;]Q<@=;P=;]@=;V><<<=;\\L<@=<=Q=;VL=;:W=;W^=<;X=;WN=;dR<BN=;Xd<MC=;UC=;K>=<;V=;:W<LT=;W^=;UU=<:@<@==<:B=;ZK=<:L=;[S=;WV=;Vb<AC=;YO=;@<=<:T=<;c=;U`=;:W=<:X=;VU=;U`;S=<::<AC=<<W<W<=;W<=;]Q;Q=<:\\=;W^=<<^=;U>=;\\>=;]]=<;B=<;K=;U@=;]S=;\\b<@C=;VM<<=<@==;^d<@B=;bZ=;_P<@P<`M=;]S=;_P=;]]=;ZC=<<B<AC=;RT<BN<@?=<;U=;NP;\\=<;Y=;_:=<=[=<;]<@==;dS<AC=<;`=;b[<BN<>:=<;d=;dY=;W^<;R=;VL=;UY=;U`<@O<BN<<`=<;O=<:R=;[:<@==;]S<@N<`M=;^U=<<P=;YL=;^d<@M<`M=;]Q=;]Q=;^d=;U[=;XU=;_T=;U`<;W=<<X<A?=<>a=<:_<;S=<>@=;U<=<:A=<:C=<<B=;Wd=<:O=;b:<BN=<<O=<>:=<:V=<<S=;WX=<<U<@=<;N=<>b=<?R=<:b=;UO=;]Q=<;C=;W?=;W^=<?Y<A?=<<c<`M=<;C=;VA<BN<>O=;Za=<;N=<;P=<;R=<=V=<:C=<=Y<@=;M=<=\\=;W^=<@A=<=_=<=a=;Xc<@=<MC=;LR=<;c=;dX=<<;=;X]<?^<NL=;VM=<?=<@==<>C<AC=;^U=;]Q=;`W<A?=<>Q=<>S=<;N=;bW=;^d<>L=<>Y=<>M=<>\\=;\\N=;WW<P[=;U`<?_=<@W=<:_=<AC=<<>=<<@=;^<=<:X=<=\\=<>N=;bC=<>N=<<P<@==<>;=<<R=<>M=;db=;WX=<@W=;XL=;X]<@?=<@W=<<\\<@=<?`=<AK=;_:=<Ad=<<b=<;A<@==<?`=;Zd<@==<?c<_c=;\\b=<@;=<;S=<=W=<@?<;L=<@B=;X]=<BQ=<B==<<d=;UY=;NP<W_=;W<=;NP<?W=<B:=;W^=<B\\=;];=<;V<^d<UA=;UY<MC=;b]=;ZK=;UO<MC<?[=<B]=;X]=<C?=<:_<?N=<A]=<=c=;\\M=<@X=;dY=<C;=;^Z=<@O=<>^=;W<<MC<?M=<C@=;dN=<@W=;XT<MC<^d=;b]=;UY<LT=;b`=;^L=;dY<@a=<A]=;_:=<Cd=;U>=;Xd<LT=<CN=;UY=;RT=<Ca=<CR<LT=<A@=;UO<LT<A==<CX<A?=<KP=<B`<LT<^d=;b`=<KA<@==;bc=<C<=<;S<@\\=<KQ<@==<K]=<:_<@_=<CL=<;S=<K@=;U<=;\\b=<KZ=<CR=;RT=<KM=<;S<@^=<K^=<LB=<B`=;RT=;bb=<CO=;\\b<>K=<:C=;VU=;\\b<@U=<K:=;W^=<LU=<K==<;N=<L:=<:V=<LQ<AC<^U=;\\b=<A@=<LS<@==<LX=;W]=;X]=<Ld=;W^<@L=<@W<@;<LB=;\\b=;_]=<@Y=;^Y=<A[<@N=<LV=;X]=<MN=<LY=;U`=<L[=;]Q=;^Y=;bX=<AY=;:W=;UY=;]Q<>C=<:C=<?W=<BB=<K^<>O=<@W=<MZ<PN=<M]=<>M=<Ma=<?Z=;X]=<N<=;_:<>A=<Kc=;]Q=<L[=;]S=<M\\=<Cb=;]S<>;=<MO<AC=<NP=<:_<>:=<Mb=;U<=;]S<>B<BN<^U=;]Q=;WW=;UY=;]S<>P=<LR=<>P<@=<=^=<NQ<A?=<Nd=<LY=;]S=<L[=;^U=<N`=<L^=<Nb=<N]=;U<=;^U=<?c=<K[=;^U<=b=<K^=<OQ=<:_<=W=<Kc=;^U=<L[=;^d=<ON=<CR=;^U=<OK=<=B<@=<>N=<Na=;^d<=Y=<O:<@==<Oc=<LY=;^d=<L[=;_P=<O`=<OB=;^d=<O]=;_P=<@[=;WX=;UO=;_P<?>=<K^=<PP=<:_<?C=<Kc=;_P=<L[=;XZ=<PL=;bX=<=Q=;XA=;UY=;XZ<>M=<N:=;XZ<>b=<K^=<Pb=<:_<?<=<Kc=;XZ=<L[=;_`=<P_=<OB=;XZ=<O]=;_`=;ZT=<Cb=;_`<>Y=<Od=<QO=<LY=;_`=<L[=;`>=<QL=<CR=;_`=<O]=;`><><=<Na=;`><>R=<Od=<Q^=;WN=<QZ=;U[=;X<=;`>=;`><>;=<PM=<K_<@=<<:=<K^=<R@=<Qa=<AW=<N:=;`><>V=<K^=<RN=<:_<<Q=<NV=<R>=<>;=;X;=<R>=<R;=<?P=<R>=<RR=<;;=;X]=<R[=;_:=<RB=<CO=;`><>A=<Q\\<@=<<U=<Od=<S;=<:_=<R`=;UY=;`><RX=<K[=;`><<B=<K^=<SL=<:_<<==<RS=<SA=<Qc=<RW<@==<R<=;X@=;`>=<SP=<R\\<AC=<SY=<R_=<SQ=<SU=<Rd<<c=<Od=<Sa=<LY=;`>=<L[=;[R=<Q[=<Cb=;[R<;d=<Od=<T@=;WN=<T<=<SS=;[R=;[R=<SV=;VU=<T?=<TA=<@W=;W^<<d=<RS=;[R=<RU=<R==;[R<=P=<K^=<T[=<:_<=T=<TV=<RK=<RV=<TM=<S_=;W<=;[R=<TU=<N=<AC=<U<=<CO=;[R=<Rc=<T><@=<=A=<Od=<UL=<:_=<U?=;UY=;[R=<SB=<RY=;[R<=B=<Od=<UV=<TC<@==<US=;XT=<Tc=<SV=;UO=<U;=<K^=<UP=;U<=<TN=<NZ=<R>=<O]=<TK=<UC<<[=<Od=<V?=<UY=<T==;XS=;X<=<Tc<>?=<UT<@==<VA=<M:<AC=<VQ=;W^;`=<T`=<VN=<UC<<_=<Od=<VZ=<:_=<VV=<UY=<US=;X@=;[R;M=<Od=<Vc=<V_=<TL<@==;[R=<VN=<Va=<@@=<Vd=<Kc=;[R=<L[<NO=<VC=;W<<NO;S=<K^=<WQ=<:_;W=<RS=<WM=<SS<NO<NO=<W?=;UO<NO;N=<K^=<W^=;WN=<WZ=<Na<NO;K=<Od=<X:=<:_=<W`=<CO<NO=<V`=;VU=<W]=<Od=<X>=;UY=<X@=<WX<@==<Wb=;bX=;[R=<O]<NO<>>=<N:<NO<;O=<K^=<XY=<Wa=;OL=<Wc<@=<;W=<Od=<X`=<X\\=<VC=;XT=<WY<@==<XV=<WO<@==<X[=;V\\=;X]=<Y@=<XM<Q==<XW<@=<;[=<K^=<YO=<:_<;<=<WV=<YL=<RV=<Y;<`Z=;X@<NO=<YS=<SZ<A?=<Y[=<@N<NO=<L[=;`d=<XV=<Cb=;`d<;R=<Od=<Z;=<:_<;==<RS=;`d=<WN=;VU=;`d<;C=<Od=<ZL=;WN=<ZA=<SS=;`d=<Yb=<RY=<ZK=<ZM=<TS=;X]=<Z?=<ZO=<YU=<R==;`d;b=<K^=<Z^=<Z>=<Z@=<Z[=;XT=<ZR=;=_=<CR<NO=<O]=;`d<=^=<N:=;`d<@<<@;=<U==;VA=<[K=;_:<@A=<[N=<Lc<@==;`d=<L[=;a@=<[@=<OB=;`d=<O]=;a@<=]=<Na=;a@<?^=<[Q=;_:=<[_=<LY=;a@=<L[=;aM=<[\\=<OB=;a@=<O]=;aM<=d=<N:=;aM<?b=<[N=<:_=<\\K=<:_<?W=<[Q=;Xd=;aM=<L[<`L=<\\A=<OB=;aM=<O]<`L<=c=<Na<`L<?Y=<[`=;W^=<\\^=<LY<`L=<L[<@]<];=<V:<`L=;WW=<[R=<]:=<CN=<[R=<Lb=<OB=<]:=<O]=;VU<=b=<N:=;VU<?R=<\\L=;_:=<]R=<:_<@c=<\\Q=;[c=<L[=;bO=<]O=<OB=;VU=<O]=;bO<=a=<Na=;bO<A:=<\\_=;X]=<]d=<LY=;bO=<L[=;b]=<]a=<OB=;bO=<]>=;Xd=;b]=;Y;<UA=;b`=;Y@<A?=;b`=;b`=;[@<@==;cB<=X<`M=;b`=;cB<NA=<CQ=;YT<A?=;b]=;b]<=W<BN=<^P=;bZ=;bc=<^Q=<KY=<_==<^U=;XC<=V<BN=;_`=;bc=;c^<AC=<KC=;]]=<_;=;bZ=;cB=<_<=;cB=;cB=<^U=;Xd=;YO<A?=;cB=;dM<BN=<L==;]]=<_R=;bZ=;Xb=;U?=<Rc=;XC=;XC=;YK=;[R=;dS<=U=<_B=;XB=<=`<`M=<^[=;\\?=<_a=<>O=;Xd=<_<=;Xd=;Xd=<^U=<:B=;VR<NA=;Xd=<AO=;Xa=;Zc=<=b=;cZ<A?=;dS=;Y@=<Rc=;dS=;dS=;YK<<><@==<=?=;\\`<NA=;dS=<=?=<`U=<`Y=<`\\=<`[=<<?=;dB=<aC=<:B=<^U=<=K<=Z<`M=<:B=<=K=<a<=<a@=<aC=;_K=;Xd=<=?=<MV;V<@==<=K=;^U<NA=<=N=<A><AC=<>C=;_P<NA=<>R=;\\^<BN=<>X=;d_<AC=<:B=<>X=;WN=<=?=;>C=<`Z=<=K=<`W=<>;=<=?=;:W=<=N=;W^<>c=<[N=;W<=<>R<?@=<]S=;W^=<bY=<PS=<[N=;UY=<>X=<a^=<@N=<A;=<>R=<OB=<>X=;WW=;^^<@==<>X=<bU<W<=;^d=<bT=<]X=<>X=;_?=<c>=<BA=;ZP=<>X=<BO=<`d<@=<=Z=<[N=<;Z=;X]=<cU=;XO=<Rc=<=?=;b`<?A=;VM=;[R=<=N<?@<BN<?L=<cS=<=N=;VT=<cS<>Z=<^:<MK=<[N=;U@=<=K=<=?<??<A?=<c^=<=K=;dP=;U<=<=K=;V<=;X<=<=K=<=K=;V?=<c`=;_S<AC=<dN=;Y:=<?]=<a\\=;UA<LB=<=N<Pa=<M@=<@Z=<>N=<:K<@==<>R<K>=<<[=<<L<A?=<PY=;^@=<?K<AC<MC<AC=;@<=<]:==:N=;WL==:K<A?=;bO=<`Z=<b`=<;_<@==<A;=;_K<^U=<c;=;XA=;X@=<>X<<V=<d?<A?==:a=<:_<<K=<cK=<Nb=<`Z==:Z<BN=<c^==:]=<LY==:W==;>=<dY=<CR==:]=<d<=<>X<<M==:b<@===;R=<:_<<;==;<=<MV=;Xd=<A;=;VC==;A=<d\\=<[R==;K=<bb=<Ac=<V:==;O=<RY=<>X<;`==;S==<<=<:_<;]==;X==:X=<A;=;VP==;]=;^>==;_<@==<ba=<[R=<A;=;]Z==:\\=<CT=;VU=<>X<=O==;S==<X=<T^==<A==;L=;]Z==<L=;_<=<cN==<P==;Z=;`Q==;c==<U=<cN<=?==;S=====<:_<=K==<\\==;a=;WS==<_==;C<@==<ad==;a=;`T==<T=<L@=<>X<=;=<bZ=;X]===U===M=<aa==<c<W_=;XT=<LQ<_c=;cT=;]d=<>X=<LQ===M===O==<Q=;`_===:===S<@=<<]===V<AC==>@===Y==<B==><=<RV=<LQ=;Qd===`=<cN===c=<CO=<>X=<CN<a;=<cN=<>X=;\\Q<A?=<A;<bC<NA=<LQ=<@M<AC===b=;XA=;Y^=<>X=<cd<?K=;_T=;]Q;T==>A<A?==??=<:_;L=<bV=;VU<YB==?K=<Y\\<@===?O==;a=<;P=<@N=<LQ=;`^<^U=<A;=<La==:Y==?Q==;S==?R=<<<=<b^=;[R=<A;=;^O=;aV<;V=<cN=;bT=<A;<@T<O^=<>X<>d=;_S==>d<@==;ZZ=;^b=;V==<A;=<>X=;U_==>[==?[=;Ub==?Y=<BA=<A;=;VX==:;=<LQ<UA=<<K=<>N=<cQ==:@==?[=<<A<@==<=N<YB=;US==@_=<L]==@_=<L==<>N==?T=<>N=<BY=;]S=<>C=;UQ=;bV=;@<==A<=<>N=;]]=;@<==A>=;@<=;`T=;Xd=<M\\=<bd=<@N=<NY=<aS=<CR=<M\\=<L@=<M\\<;M==?@<@===A`=<:_<;Q=<b^=;U<=<NY<>a=;cQ=<N`<?==<=W=<Md=<OA==:c=<Md<NA=;ZV=<NY=;dV<@=<;d<@==<N`==A@=<;L=<MV<A?=<O`==<P<A?=<P_=<aa<\\_<@==;_`<NA=<Q[==>:<A?=<R<=<b<=<:U=<b?<A?=<Rc=;`><NA<RX=;`N<A?==BS=<VN=;`Z<BN=<XV=;`d<NA<=`=;aa<NA<`Z=;a@<NA=<[@=;aM<NA=<[\\=;aX<CU=;[c<NA=<\\[=;X:<A?=<]O=<]A<U\\=;dY=<`Z=<^X==:M=<@N=<^b==:U=;c_=<Md=<^b=;UX=;[R=<N`=;_R=;_L=;U<=<?c=<bL=<@N=<O`=<NY=<:U=<?c=;:W=<P_=;W^<?a<W;=<RY=<Q[==K^==?P==Kb=;XS;`==BT==L<<BS=<=X=<BB=;`_==K_=<cW<NB==K_=<UK==L@==KX<A?=;^b=<?c=<N`=<?c<@d;W==L@=<?c<N@<A;;A==L@<?Q==K_<N@=;W^==L]=<LY=<O`=<=N=;_L=;XC=<P_<?:=<>]<@==<P_=<P_<>\\=<>O=;ZT<>[<`M=<Q[=<OZ<K?=<X]=<MY==B_<>Z<`M=<O`=;ZT==A:<AC<A:==LL=;Xd==Lc=;VV=<XV==M<==M>==M@<VL==MC<X`==MM==L@<NA=<P_=<Q[==MR<@==;ZT==MT<NA==MV=;VL=;XT=<P@=;bY=;X@=<O`<@W==LL=;_:==NS=<B`==NO=;b`==NQ=<^V==NT=;W^==NV=<VK=<O_<AC=;bc==NZ==N^=<A^<AC==N^==NN<AC=;b]=;W<=<O`<>P==K_=<:_==OB=<<[=;VU<MC==OL=<VR=;LS==M[==N`=<PY<T>=<Q@=;YQ=;Y^=<P_<ZT<BM==OY<@=<>_<@=<>^==C`=<P_=;[V<>T==Ob=<;M<>S=;^<=;ZT<O^==:?=<>N=;][=;dN==:S==@b==PL=;\\T==@_==K@=<>N=<@=<?X==@:=<P_<>R==NA=<dM==N`==<M<YX=<O`==NO=;XT=<P_=;Xd<>Q=<R===N>==OC=;_:<><==K_=;W^<>?==K_==P_=<[R<>X=<RY=<P_==Q?==?P==QM=<c_==N`=;UO==O:<A?<>>==K_=;c[=<O`=;ZV==@a=<P_<T>==@\\=;@<==Ld==@_=<`C=;XA=;ZT=;_]<O@<@=<>U<`M=;ZT=;ZT=<VC=<X]=;\\C==C:==PM=;bW=<>;<<T==M>=<>;=<>;<cT=;YL=<Rc<<R<`M=<>;=;\\W=<;c=<>;<<Q=<@N=<Rc==>:=;Xd<RX=<QV=;bX=<Rc==?Z=<Rc<K<==?P==S;=;XS=<Rc=<_c<@=<<X<A?=;]Q=<VN==C<==QT==PX<NA=<VN=<Yc<BN=<UB=;\\?=<Q[==ST=;UY=<Rc==<b=<UZ==RA=<CR==Rc=;^]=;^_=<Rc=;KY<W<<<W=;_:==Sb=;_:<V]=;U><=A<@==<Rc=<VC==LZ==T@<@=<>R==K_=;_R=;W^==TM=;cX=<Rc=;X:==R_=<Ta==KK=<Rc<RX=<LY==SV<BN;N==TK==B^==S[=<QV=;V==<VN=;XC=;ZP<^V==S\\=;:X=<Z[<A]=;UZ==:;=<Rc<K`<W<<XP==Q^==PL=<R<==:Q<A?=<_L=;@<==R@=;@<=<TX=<>N==Ba==@_==Ra=;@<=<aa=;@<=<`C==:;<RX<YX=;W?=<>N==A>;]<@==<VN==Cc=<Y<=;\\B=<>O==CT=;\\>=;\\N=<YL==CT<<L=<:V==VK<@=<<K=<>O<`Z==VB==VN<`Z<`Z==VM=;V===VV<@==;]d=;YL=<[@==VT=;V==<[@=<[@==VX=;X<==Va<@=<<B==KK=<XV=<[@==OM=<W=<@=<=K==N\\=;X]==WC=;WN==CT==SZ<`Z==CK=;bX==CT=<c<==L[==CT==WM=<O^=;W^==WX=;W<=<VN<;d==Q:=;W^==W^===@==Q@=;X<==CT<A?=;\\Z==Wd=<YL<<P=<R===WW==W_==WL==Wc=<Z[=;Ya<<b==X>=<?d=;YL==CT=<_<==CT==CT=<^X=;V===XT<@==<^b==XW=<YL<<O==VN==XX=<:X=;]S=<[@=;VW=;\\B=;@<==SR==PB==PL==WR=;]d==CT==W?=<;>==K_=<U:<@=<<d==XB=<U>==Q==;X]<=<==QV=;U<==WO==:X==WQ=<V:==WT==S_=<YL<<\\==K_=<cB=;X]==Y\\=<LY==CT==Q_=;c[<`Z<<N==;@=<YL=<dP=<YL==RN=;U?;:==VO<<M<BN==XR=<P\\<A?<`Z==Z@==VU=<[;==ZK<AC<`Z==@\\=<O;=<[;==X:<KP=;V[=;Y^=<[\\=<=A=<;U==Z]<@=<<;<@===Z`==Z[<<:==Zd=;[Y<==<]L<@=<<A==[===Za<<@==[C==Z[<<?==[M==[@=<`c==[:==[@<;`==[P=<[\\<;_<@=<;^==C`=<[\\<;]==BR==[[<@=<;c==[Y==[_<;b<@==;^_==Za=;^_==\\;=;RT=<[\\<=P<@=<=O=;]>==[@<=N<@=<=M=;[Y==P:=<[\\<=T<@=<=S==[_=;Y===\\S==Za<bC=;bT==Za=<;X==T?==C_<`N=<\\[<`N=<]O=<^A=;^<=<^X=;V_=<dY=;@<==ZZ=<>N=<\\V==@_==\\a==@_==\\d=<>N=<\\<==@_<`Z==UP=<Nc<BN;U==XY==;M=;YL=<_A<=@<`M=<^b=<^b=<_A<AC=<_A==B[<@==<`>=<^b<NA=<_A=<A@<A?=<_A<;O==YN<A?==^>=<LY=<_A==;Y==]a==]U=<dZ<@===^:=;XK<YX=<_A=<a;=;^<=<aP=;c>=;U>=;@<==]c=<@N=;>C=<aP<AC=;VR=;>C==@\\==T?=<c^==KU=<c==<c^<;?==TN=;_:==_<=<:_<;B==YS<@==<c^==Sd=<RV=<c^=<c^<=?=<@N=<cb==KU=;c[=<dL=;dd=;]c==_C<@==<dL=<LY=<c^=;Y;<`Z=<cb=<_<=<cb=<cb=<^U<bC<=L<`M=<cb==>]==Z<=;[M<AC=<cb==?<=;ZK<A?=;a@<A:<@A==?P==`M=;WN=;bT==SZ=;^O==CX=<CR=;bT==WU<Pb==B`==`N==WY=<^;==`[=<[R=;bT==`U=;XT=;^O=;b]<=K=<@N==@A==:P=;^<=;ZZ=;cP=;;P=;@<=<dL==]Q==Q_<@===BA==@A=;ZZ<NA=;bT==`?<A?==?<==aR<BN=;bT==PQ<[O<@==<CQ=;YL==@A<=C<`M=;ZZ==a===:;=;^b=;C_==MX==aB==PL=<CQ=<>N==aL=;@<==`===aM==@K=;_;==aQ=<aU==\\Z<`M==aX<`M==`c=;bZ==@A=;cK<NA==aa=<??=;_;=;WC=;]W<V<==b===PL==KC==b?==PL=<cd<AC=;PT==@L<BN<YB==aV=;;P=;Xd=<cd==aV=;U@=;bT=;Xd<<d==^@==`Y=<N]==aZ==V_==aZ=;^O<<c==VN=;^O=;^O==XN<P[=;bT<@]==`[=;^O=;W^==c\\=<:_<@S==`[=;c[=;bT=<:[==QS==a[==`[=;XT=;bT=;bT=<cd=;W<=;aM<@W==`[=<:_==dL=<:_<@C==`^=;Xd=;^O==C[<A?=;VR=;^R==:^=;VU=;^O==dQ==?P==d\\=;_:<@B==cc=;[R=;^O==[?=<Cb<`L<>K==`^=;_:=>:<=<LY==@A==C^=;VR==@A=<<K=;W<==@A<>C==dM=;_:=>:O==KN<@===@A==dd==a><@==;ZC<W<==b\\<A?=<US=<>N==aV=<>N==?c==@_==@A==]Q<BN<@d==]Y=;^b=;ZC<=<<BN=;^b=<<K=;V===B>=;^b=<:a=;YL=;_R=;\\A<NA==B>=;_R=<^^==bC==B>=<;?=;YL<N@=;Va<BN==BA<N@=>;T=;_R==BA=;d\\=;YL==M=<<Y==bY==MB=;Qd==Ub=;@<=<b?=;]d=;_R==MB=<cZ<X===bC=>;a=;[R==M==<>L==@a==MB<_c=><===M><A?=><@==Mc=><C=>;_<@==><M=;<@<@=<<_=><:=<;V=><T==VC=><V=><K=><B==S>=><K=>;`==QP==M=<<^=><`<MC=><b==VN=><d=><A==NM==Sa=><L=>=?==>?=><`=;W\\==^X=><U=<X_=>=:==NM<A?=;_R=>;V=<>O==M==<=[<NA=;_R==M==>;T<N@=;_R=>;a<A?==MB=;_@==@a==ML=;Wb=<?B=>:\\==PL=<^X==_W<N@==ML=><C=>>:<@=;Z==QP==MB;Y==bY==ML=;\\b==Q]=;AP==PL==]N=>=X=>>O=>=Z<@=<N@=>=]=;YL==MB==L;<NA<N@==MB=>;T==M=<N@=>>T=;YL==ML;_==bY==MT=;U`=>=K==]]=><d==M===MT=><C=>?A=>>S==QP==ML;^=>?N=<>M=>=K=<`>==_W=>?T=>=O=><]<N@=><\\==ML==V:==@a==MT=;]S=;VB==@_=>?R=<>N=>?_==@_==b@<AC==U\\<`[==PL==:B=>=W=;^O=>?a=;XO<A?=>?W;T=<>O==ML=<<W<NA==MT==_S<Z;==;M==:;<BM=;^U=>=K=<`T<A?=<cd==M=<BM==c?<@==;\\`==M==<_b=>?c=><[=>?Y<@=;R=>?\\=;^d==PA=;@<=>A;==ba==]Q==^Z=<>N==>:=><>==PL==C<=;]d=>@U=>=<=>?W=>@:<@==<<^=>@====N=;VL<Q\\=>AT==PL=>@M<A?=>AX=;@<=>AZ=<ab==PL==UX=<>N=<b?=<>a=>A_=;V===M==>>d<A?==ML;X<`M==M===ML=>;T==MB==M===LV=;YL==MT=<a[==@a<>Y=;_W==b;<AC==CR=>@L==PL=<cb==]Q=<c^==_W==MB=>Bd=><C=>B]<@==>B_=;[R==MT==]T=>Bc==B`=;VL<V^==b<==]Q==`U=>AV=><d=>CK=>?b=>CN=>CP<@===MT;L==bY=>Bd=;`>=>>[==@R==aK<BN=<>R=>C]=;X:=>=;==VC==ML=;b`=<cb=;V===ML==ML=;UU=>KO<@===ML;C==VN=>KP<@=;B=>KW=>KT=<;Q=>K[==ML;O=>K^<@===T]=>KS==ML=<@A=;bX=>??==dY==Mc;C=>:==;W^=>L@<W<=;Z@==MB;==><K=;U@==ML==M==><\\=>Bd;<==bY<BM=;[R<_^==A;==PL==PC=><c==V[=>K\\<BM=><C=>LQ=>AM=;c[=>Bd;;=>LV=<XP=<:\\=<>N==aP=><d==ML=>L`=>=<=>Lb=>LS<@===ZB==@a<BM=<[B=;^?==MP==_W=>MB=>?b=>ML==QP=>Bd==L[=>MP<@==;a@=>=K==ST=>L^=>MV=>La=><]=>MM;@=>M<=;aM=>LY=<>N=>@R=<^R=>B?=<^c=>L_=>>a=>KL==_X=;YL=>Bd=>C@<BN==ML=>Bd=;UM=>BV<@=<;K=>LA=;X]=>NX=>LK=;RT==ML=;`P;><A?<YX==MT==NC==N_=>Bd=;b`<A>=;U@=>Bd=>Bd==X`==O^<W@=<:b==@_==ML==]Q=>Nd==@]==PL==aC==@_=>NQ==Y<<AC=;C_=>Bd==O_=;]]==MT=>Bd==VC=>O\\==><=;Y^=>Bd<CA=<AV=<?a<Q]<`N=;]`==Pb==V==;ZP==V==<B@==V=<A?=<ba<^B<Y<<>`<Oa<^A<TV=;TO=;MA=<BB<O`<Ob<Od<P;<P=<P?<W?<B><B@<BB<O;<BM<b@<`Q=;@<=;Sa<`a<V?=<@Q<`A<KM<?=<Y_=;LW<>T<=Y<`=<V?<Pa=;Q><OK<\\]<X_<OP=;?]=;RZ<^Q<^S<@:=;d>=;R?=;L\\<>O=>PU<>Z=;QW=;RX<CS=;=K=;S?=;B^=;cd<ML<MN<W\\<_=<R_<@K<@T<@V<@V<@S<@V<@U<@T<Mc<YQ<_S<YS<AN<`N<BP<_W<>K<_Y<>c<_[<aM<_^<YQ=;AT<SC<VU=>QV<X<=;KT=;K<=;P><]L=;S?=>Rc<VQ<VS=;OZ<KR=;S^<\\R<^_<K[<K]=;N?<KZ<Kc=>Q^=;QY=;BX=;Lc<LK=;K=<@==;Na<@:==ZT=;BU<`_=>Q\\<@d<B^<dd<WQ<aZ<d?<>]=;T]<M:=>QK<K;<dQ<b\\<aT<>T<@`<Nb<aX<Nd=>PN<LZ=;B=<d?<B`<Ca<`a<aN<@d<><<?C<cL<a:<ZX<?:<aM<dS<SY=;?C<OC<NW=;>Q=>TC<M:<ZW<Yc=>TW<NW<`b<@d<@W<@L<@X<dP<>]<cK<SA=;<=<cB<C:<VV<cR<W?<M@<MB<_:=>R;<QS<MR<R_<MW<MY<M[<M]<M_<@T<Ma<Mc<Pa<N;<N=<Q:<`N<?V<>L=>M`=>KZ<`M=;W<=;[X=<[L=<<C=;_:=;^;=>KY<`N=;U@<BN=;U>=>CB==;^=>V?=;[<=;X<=;\\;==\\K=;[;<LN=>VU=;<?=>VA=;[?=<<_=;X]==P@=;_:=;cP=<S:=<;K<@==>M;=;[;=;bW=;[]=>L]==`C<NA=<?Z<BN=;cP=;W^==:><A?=>VU<X_=>V^=><<=<YA<AC=>WT=;W^=;W\\=;VN=;[W==N_==BB=;c[=>@@==^N=;[M=;U>=>VU=;Y@=>VW=;[N=>X:=;_V=;X@=<;c==?P=<>;=>Wb=<=;=>X<==>c=<@=<AQ<AB=>WZ=;@<=>X>==WA==?P=>LX=<=:=>Od=<CO<A?<X<<@d==A[<A?=<Bc=<?a=;`^=>VX=;:W=;b?<@=<CA<O^=>Xc=;a[==C`=>Na=;[:=>Xc=;Yd=>VQ=;dZ=;YL=;:W=<@Q=;[O=<;M=;\\K=;d<=>VX=;Ub=>XW=;[P=>WL=<>@=<?a=;d>==:;=;<?=>=K<NA==Zc=<<K=;X:==MX=<>O=>YM==M>=;WW<^d=;\\K=;d@=;Zc=>YT=;Zd=>;T=;W?=;NP=;YL<ON==aY=;dZ=;Y]=;[X=<KL==C`<AB=;RT=;\\b=;Y^=;]L=<>M=>ZW=<Nb==<P==A:=>PB<BN=>PA=<;K<X_<BB<\\M=;?]=;;><AX<AZ<W?=;=c<KM=;WS==[L<`M==C>=<BA=>Wa<`N=>=W=;[M=>[K<ON=>Y[=;UZ=;U>=>L;<`M=;]d=>[M=<B?=<;K=;VX=;VX=>PL<^K<>S=;Ub=>VU=>;:=>M`=;XK=>VS==<M=>Z`=>[N=<@c=;Y>=>QM<OB=>QO=;<K<WO<Q@=>QS=;S?=>QU<_V=>QX=;L[<^Y=>Q[<Oa=>Q]=;RV=;QX=;B\\<^_=>Qb<^c=>UU<_<=>UX<MU=>R?=>RA=>RC=>RL=>RN=;@W<_T=>RR<`M=>RT<X<=>RV<Od=>RX<cZ=>R[<^V<^Y<PL<]b=;<=<]O<=Y=;;[<]B=;?]<VR=;KR<W?<AL<_V=>Ra<KA<KC=>]V=;T@=>S@<KU<KW=>SC<]\\=>SL=;=V<Kb<Kd=>\\X=>Q_=;Lb<LC<>`<W:=>PQ=>QA<BB=>SW=<VC<OA<SM<c@<aM<@d=;M]=;>Y<SK=;>T<bL<LQ=;>X=;>Z=;>\\=;>^<c<=;>a=;??=;P_=>T><`;=;?@=;?B=;?K<Q<<`b<`S<RB=;VX<BZ=;VX=;?R=>UR<SA=;BT<V=<YM=>QL<N:<N<=>\\Z<Pa<?L=>_U=>V:=;a:<>L==CA=;VM=>?M=>XW=>[K==N@=>N>=;dA=>Xb=;ZR==OX==BB<BS=>Xc=;_c=>Y>==<d=>X^=;VL<]b=;a\\==@d=<>O<W<<RK=>[S=<?a=>=V<`N=;W\\==<M=>XW=;bW=;:W=;=^=>YO=;YW=;[X=;YZ=;[M=>Z@=;VX=>ZB=>YX=>ZL=;bU=;\\U=;W]=>ZS=;cL=<>O<LB=;cd=;YL<A\\=>YR=;YL<BS=;d>=<:C=<>^=>aM<@==>Z>=;[]<LB<BS<[<<AB=;C_<LB=;\\R=<CS=;aV=;[X=;NP=>a[=;[]=<@=<P[<LB=;_P=>VC=>b;==QP=<MA=;ZX==@:<AB<LT<PA=;]d=>Z]=>XV=;Zd=>[]<V_=;A>=;TS=;AO<PB<Kc<A`=>[><OL=>[A=>VO<`M==V==>`W=>b[=;VK=>[Q=;^<=>Y\\=;XK=>[V<NA=>[X==;^=>\\==>bO<V_<TV<^C=>PN<^L=>[a=>VO=>[d=>VR=;Zc=;U>=>c><`N<W?<_W<`==>_A<K<=>]Z=>QV<TV<\\`<R\\=;KT<WC<YS<?@<]K<?V==ZZ=;Y;=<?a=;<?=;V==;W?=;]`=;]`=>`;=>d:=;YQ=>Z@=;YB=>W[=>CV=>\\>=<B>=>Z^=>\\>=>Z^=>cT<X<=>cV=>PN<V?=>cY<_V=>c[<YK=>c^<W?<@^=>c`=;WP<;\\=<;K=;YL==ZW=>d==>dN=;YP=>cS=<aB=;]K=;[C=;[>=;ZN=>_c=>dO=?:L=>`X=;U^=>bQ<BT=>cZ=;M`=>d\\<W]=>d^<RT<@Q=;Vc==[]=>_`=;dA=<aU=?:O=>dB<AB=>d@=<>^=>Z@=<<d=?:M=>Z^=>Zb=>dY=;=C=?:S=>c]=?:U<AC<WK<K;=?:Y=<=;=?:\\==aS<NA=<:N=;bW=?:`=>_d=;dZ=?:]=?;:=?:M=;]]=;dV=;]]=>cR=>W;=;X:=?;\\<`N=?;^=>W;<BN=<@Q=>PS<Td<?:<U;<BV<^S<[Q<\\;=;@]=>PW<UK=;:_<UO<Pa<CC=;NN<CL<YW<UQ<>`=;KP<[d<BV<U?=;CR<VM<VB<QU<YQ=;QW<^A==`==>^R=;>M<aL=;>O<b;=;>R=>^Y=;>U<`^=>^\\=?=;=;>[=;>]<NW=;>_<a\\<TS=;??<L^<@_=>][<M:=;B==;QQ=>PW<L?=;>[<Q?=;La=>S]=>TN<ZL=>T<=;?A<Vb=;?C=>T<=>_?=;S]<RQ==NT=>_K<AC=>_M<CU<LQ<B;=>OM<_X<M:<dA<>_=?=L<B`<d@<dB<BK=;Q@=>U==>TY<KM<AY<cC<[Q<dC<N^=;?K=>^d<AX<NR<NT<NV=>_:<N[<@M=>^Z=?>L<bd<c=<M:<AX<KT=;PP=;O<<`d<?;=?=P<^S<ac<[?<@_=?=U<QT<cR=;:A=;SK=;:L=;K]<`[=;:P=??S=;:S<?;=;:U=;<?<L:<Q<=;:^<RO<??=;:a==[<<A?=>RV=?>C<dB<WS=?@<=?>L=?>Q<d\\=?>S<Oa=?>U=>Sb<cK=>T;<`?=?>\\<SV=?>_<VO=?>a<aU=>UC=?>X<=c<><=?=W=???=;QZ<C;=?>c=;>U<cc<\\?=??<=?@[=;@Y=?>V=>TN<dN<CN<Vb<P:<d?<??<LZ=?=O=?=Q=??M=?=T<Sb=??Q=>R_=>]\\<K?=>]^<\\[=>]V=;=^=;Q`<SC=;Cd<KK<XB=;KN<=Y=?<U=;:_=<NM<[X=;V\\=;bZ=>`W=>a:=;<?=;\\K<X_=>a\\=>`a=;YQ=;WN=;\\<=<`Z=?;Q=<;c=;WW<AB=;Wa=<:b=;^M=>Xd=<?T==AL=?BP=;WN==L>=;VV=;bc=;_\\=;bZ=;`:=;bZ<K>=;]Z=<<L==cP==<d=;WS=;_V<AQ=;WS<BS=>b^=;VC<BN<Pa=>ZP==;b=;`]==C`<AQ=>Y:=?CL<@==>Y==<dc=?B`==PT==;b<YX<XP=;\\><C^=;X:=;]d<BS=?CY=;WX=<;U=;WR=<BR<AC=>WO=>V^=>@d=>WU=>PC=?K;=>M]=;XK=>KZ=?:d=;ZV<X_=;Y]=;RT<ON=>X^=;Z@<ON=?CN=?KO=?CP=;ac=<dc<AB=;VX=?CT<ON<YX<LN=;\\>=?KV<BN=;]d=<;Z=?K?==;^=;VM=<M\\<ON=;dV=;[=<ON<^U=>a\\=;PT=?;P=>dM==aS=;]]=>dL=>a<=?B<=;[]=;dV=>aC=;cY<NA<BS=>WR=;]S<AQ=;^><LN=>[V=;Ub=>[V=;ZN=;]\\==PL=;]`=;b]=;_Z=;Ua=<aU<ON=>Z@=>Z@=;[X=?:d=>XW=?:a==V?=>OC==V===]<=?;[=?;b=>`X=;]`<`L=?MC=<AR=>bN=>PB<@<=>cT=;dV=;KT<TX<BV<>N=;NR=;=A<ba<QU<W?=;;>=;=<<]:=?MY<>`=?M[<WW<>d=?M]<YV<W?<L:<C<=;cd=>VN=?:d=;VR=;^>=<d<=;\\<==?P=<?A=<B^=?Ka=>b^=?NM=<AR=>KZ<ON=>V]==NO==Ua=;[>=?NS<W<=<c==;Z`=>VC=?BU=;X]=?N\\=;UY=?NY=<SS=>dL=;U_=;X<=>dL<LN<ZT=?O<<AC=?K@=?MA=<cb=?M@=?;U=>VX<`N=?M>=?MM=;UW=<K:=>Zc=>bS=;`T=>[b=<N:=>VB=?K==?K]=>WN=?Ka=>XW=>XR=>WO==d<=?Od=?O[=>AK=>YC==_X=>[Y=?;_=>XY=>c@<Ka=>SK<K^<]:=>^>=>SP=>\\Z=>SS=>^K=?;><LO=>^N=;BN=?>?<@:=<CN=;Na=;NY<C;<KT=;Q@=?=K=;SR<Cb=;RW<b><M?=>_O==K@=>R:=>\\_<_><MV<MX<MZ<M\\<M^<M`<Mb<@T<Q<=>Uc=;B\\<`N<NC=<@==<dd=?OT=;^>=;X:=>`W=>YO=;V:=;[S=?:d=;Y\\==C`<LB=?M:=;_T<A\\=?Od=<[a=<>@=;_N=;_T=;a]==@:=;]O=;_T=>KZ=;^\\=<Cb<A\\==b:==OQ=;cY=>XB<A\\=>WR=?BR=?RM==d<=?RT=?RB=;\\?=>KZ=?LT=<V:=;^\\=;UM=;UO<A\\=;WC=<:_=;WC=;c[<A\\<Pa=?CT=>aV=;^`<@?<K`<A\\=;NP=>VC=?SA==QP=?Qc=>b@=;YQ<C^<P[=?K_=?BA=?MS=?OS=>YR=;?W=>\\B=;NB=>\\K=>>b=>\\M<]:<OT<Kc<cZ<TB<Pd=;BX<]b=?S]<OV<aM<PC<PL=?PW<[V<]b=?@;=?>O=?>L=?@>==@^==aT;W;W<>K=?QO=>_Y<N?=?QR<`Q=??Y=;:K=;:M=??W<Q[<OS=??T=??\\=;RU=??_=;:_=??b=;?V<Pa=;=c<OA<>^=?<<=?PT<]L=?PL=>SM=?U>=>SO=>^@=>SQ=;A^<LO=>ST=;BP=>T?=?Q:<CS=>P[<B?<BA<VK<X\\<\\?=>[:<O[=;<O<Ab<BL==OW==Ab=<B>=>[M=?Q[=?QY=;[M=?Bb=?LL=>Xa==ZN=;[>=<_<=>dL==N@=?BO=?:A==RX=;dZ<LB<P[<AB=>Vb=<\\M=?R;=;[S<YQ=;X@<W<=;c>==d<=;c>=;c[=?S<=<Cb<LB=?VW=;_:=;c>=;W^=>WT=;]C<AC<AQ=;X@<LB=>:Y=?RN=?W==?Va=?VR<LB=><>=;X<<YQ<K>=;X@<A\\=;W\\==d<=;W`=;X]=>>B=?Rc=;bY=<RV<TV=;X?=;VU=;^X=<?T=>@?=<K;=?VR<BS<]b=;XT<Pa<O^==:;==:C<LN=;@<=;VP=;]_==PL=;]]=>[V=?KW<;[=;XA<T>=;_d=;ZW=;V==;`@=;ac=;YL<UA=>`_==>M==@B==X;=;[:<ZT<[<<YB=?:@=;UV<X_=?X[=;bX<CA=?X`<AQ<LB=?X`=?WM=;ac==><<YB=>aW=?XX<O^==AQ==><=?Q[<C^=?L@==VN=?XQ=<@Q==<d<VK==:;==@[=<AR=?L^==]Q=;]`=;]d<C^=?YU=?VU==N`==?P=<O`=<B==?C]<AC=>;d=?Yb=?YO=;[><^d=?XP=;]a=>YR=;]a=<]>=?Ba=>Z_=<;K=;YS=?:P==BY<VB=?U==>cB=>PO==PQ=>KZ==Cc=;W<=>bM=<:_=?O_=;X]=>VM=?ZU<`M=;Xd=?:d==_\\=>VT=>M>=;XS=>N`=;W?=;X:=?OP=>LY=>Ya=;ZW<P[<W<==Q\\=?K==?[C=;W^==Xc=>VN=?::==TS=<AR=?Za==<M=?Z]==@X=;UO<W<=?RM=<:_=?RM=?W@=>XB==Ub=>=<=;W?=;;P=?[S=<;@==V==>;?=?:K=?PA=?OW=>cA=>PM=>PO<]b=>VN=>V@=;b?<A\\==?P=?\\L=>WP=>cM=>WC==PY=>[Y=>Wc=<Na=?XX==?P=>`N=?\\B=;[<=>cN=?\\R=>c==?OU=;X==;]_=;:N=;:P<]b=?<O<CL<c_=;BX=<<P=;A?=?N<=?>V=?S`=;La<@C<`@<C:<C<<Zd<^^<W_=?<C<>a<VS<UO==PO=?]>=>PW<d?=?]A<Q:=?]C=?]Q=?]S<XC<Tc<U:<U<=?<?=?<X=;d_=?]V=?A@<@d=?]Y<N?=?]C=?<;=?<=<U==?<W=?<A<]:<WV<VS<UU=;OP<B;=;^Y=?^:=?]@=?];<C;=?]C=?^M=;:_=?^O=;:>=<@M=<c==;[;=>VC=<:N=<LW=?Ka==Cc=;XT=?[`=<R=<W<==AL=<:_==AL=?[O<`M=<N`=>`W<[<=<<K=;]]==ZW=>YL=?MA=>d;=?^b<NA=?^d=?Ac=?Y]=?[N=;_:==Xc=;W^=><S=?\\O==V===\\M=>b^=;[;=?:a=;WW=>YV=?Ac=?_M=;ZW=?_O=;[L=<=\\=?[]=?_S=;X<=;W?<A\\=?Y]=>>Z=?RN=?`L=;W^<NO=?`?<W?=?Y]=?`P=?RN=?`T=?_@<NA=?_^=>[L=?N]=?;T=?_c==:?=?`:=?LN=;XA=?C?=?`>=?_\\=?`@=<:\\=?W:=;WZ=;aa==?P=<]:=<:_=<`N=?`d=?`X=?Kb=;YP=?`==?_b=?Y=<W<=?LW=>YC=?``=;:W=?B`=?`c=>[Z=?:N=;VA=>cT=<CN<>K<dW<Z`=?>[<?:<@d=;T<=;T>=;PN<\\[<UO=?US=>P]=?UV<NS<\\?=>RS<@M=;`T=>Ad<NA=>dd=?`Z=>[M=<AT=>d<=?:A=?bN=?`R=;]S=>bc=;;P=>c:<BN=?XB=?K^=>cP=?SS=>XW<TV=?AQ<AO=;C;<PX<_[<KT=;TA<>Z=;B^=;U^=<@M<>N<Ad<P=<dM=?ac<L^=?b:=;;\\<L`=;:^<PP<c<<B`=;T==?cM<?@<dN=?bd=;=B<a\\=;=\\<cQ<@:=;cd=;>?=;>c<CV<\\><KM=>QN=?SX<PM=?cc<?K=;B^<VK<>;=>TZ<^b=;bC=>WZ=>Wd=;VK==TC=;[]=>LY=;W^=?NR=<@U=?Oa=?bM=>XU=;Ub<YQ=;_B=>cS=?Nd=?dU=;Y@==R[=;V;=>Yc=<aK==^;=>a:=?V?=;[>=?`b=?;Q=?PA=>WB=;Y>=>YR=?a]=;;d<UY=?a`=?cN=;TB<SX<BB=>P\\<BA<W?=>P_=?bB=>]W=>S><BN==PO=?\\Y=;\\C=>XU=;X:=>\\;=<:b==BX=?aQ<A?=?b[<AC=>[V=?XA=?:==@:b=>a==@:d=;Y[=?bZ=>aP=@;?<A?=;VC=>[V=;`;=<:?=?XO=?`A=>dN=;c[=?K`=<OB=?_L=<RY<W<=>=C=?RN=@;Y=;Vd=>dM=?Z_<`M=?[b=?`?=;VX=<c=<W<=>`N<A\\=;W^=>`N=@;\\=;ZN=@;^<NA=@;`=;_:=?\\X=>c>=;VX=?;d=;^Y<Y?<R]<R_=?=Q<>Y<@^<Oa<OX<C[<SL<WZ<@]<>^<@S<@]=@<S<W>=?:Q=>dZ<^V=;TS=?cd<AZ==UX<@]=;;[<NV<@]<=`<S<<ZL<?><@M=;<=<KS=;TU<XB<@O<QQ<?><A;<ZL=;CA<@O<MW=?QN=;U^<Pa<A;<Cc<VO<K]<@O=@:V=>]Y<AC=;;a<?@=>PS<C<<LR=;A?<BU<>B<N<=@=M=>]W<]U<PM=;BC<>S<V?<X<<Q`<>T<\\M<NV=?=b=>cW=;:V<AC<MR=@:U<VK=;<]<W:<]S<OB<C=<B;<X<=;<T=;<V=;<b<\\;<AO=?c_=;?><Yc=?cb=@<d=?d>=?SW<OL=@:P=?UT=>P^<BL<`N<bA=>:c=;VM=>@K=>dB=?::=>`S=;[>=?_O=?M<=<aU==Cc=;\\^==UK=;VL=;]K=;X]=?C]=;W^=?_?=?aB=@:[==:^<BN=?NX<`M=<US=>LY=@;\\<TV=>`R=<AR=@:c==@_<NA=>XA=<CT=?[W=<=d=>VC=>WM=;X]=?SC=;XX=>:X=>V`<AC=?W?=@@V==NM=?O@=;XA=?W:=;UO=>ZM=@@Z<A?=@;Y=?aX=>VV=;[>=?aU=<RY<ON=;]Q==?P=@AB==N_=?O<<XP=>;?=>d@=?O;==<d=<RV=;\\V==;b=<RK=?O<=@?`<AC==?<=<B`=?B[<UA=;XT<C^<BS=;X?=>N;<AQ=?`T<C^=?`O=?K==@AZ=<CO=?CM=;U[==Oa=@A_=>V_=?Vd=<>^==:Q=>dB=;`R<`M<UA=?:d<K>=;:W<YB=;Ub=<R<=?N_=;^_<CA=<__<T>==N]=?K==<NY=>XB<T>=>WR<A?<O^=@B_=?KS=;W^=@C:=>VN=@B\\=<Na<T>=<>R==?P=@CB=?\\O=@C?=?OL=;ac=;ZN=<c^<T>==<M=;ZV=?[C=@CN<K`=;]`=;cK=>Y==;U>=>;?=@CR=?RN=?[Q=;UY=;aT==:X<K`=<:Q<^U=@C]=;UM=<O`<AQ=@BW=@C;=;X]=@K?=>W:=?B`=;W^=?[Q==L?<K>=<^M=;XA=;W^=@KP=;X@<C^=@B===d<=@B==;UY<K><]:<@d=;dd=@BO=;YZ=@BQ=;a:=@AU<BN<K>=?\\X=?PB=;_K=>X]=?LB=?YK==M>=;a;=<>O=@Bc=<B><YB=<:Q=?PB=>`X<K><TV=;V==@BO<ZT=;`X=?XO=?XX<YB=;]`<CA=;VP=?PB==AL=;`<=;bX==VC=@BO=;PT=?XS=?LR=@Kc=?aL=?Ob=<;U<ON=>b===LC<A?=>b==@A<=>[\\=@;<=;<_=;<V=;<X=@?;=?ba<PM=>c\\<>\\=;KT=;]Z=>BX=>[C=>b\\=?da=?bR=<>^=;]`=?K]=;VK=@?Z=?:M=@MY=>\\>=;<?=>^:<\\P<AO=;OK=;LT<PO=>UM<?K<=b<Vb<cA<?K=;_K==Z;=@MX=?\\Q=?_O=?:d=?BL=?LA==V==>Z^<VK=;?]=@>\\=>SU=;MK<\\<<_d=?UP=;=^=;=`<Y[<?K=;>>=@?>=;><==`^<@d=@O<=@O==@O>=@O<<[@<@d=?=K=?=Q<@C<AS<L\\<AY<@\\<@[<dQ<?;<?^=@O?=@OU=@O?=?=Q<@^=@ON<MS<M<<>`=@OP=@OT=@OV=@O`=@:Q<@^=>P_<@\\<@S<@[=@O_=@O`=@O<<PK<?L=@P==@P>=>dV<RQ<@\\=@OK=@MS=;KT<@\\<@b=@<P<R^<MU<Ra<Rc<S:<S<<S><C=<[T<SC=@<Y<SN<SP=;R@=;@S<ST=?@R<SX<C=<S[=>QA<S^<?C<S`<Sb=;R[<Sd<Ad<?;=@QC<L^=>d_<>_<?@<@b<@[<@[=@O^=@P>=@O==<;b<?V=>?U=<aK=?_:=?;V=>W>=@MY=?O<=?[A=;bU==?P==]<=?_@=?dM=>d>==N_=>WK=?ZW=?BS=?Nb=?K==@Qd=?Z]=>V]=?a==@Qd=;_:=@RC=?MR=@;S=>dM=@<B=@MC=?;`=;dV=@>W=>@W<VP<CB=;?U=?UU<AC<ZX<L^<B;==d;==]a=;TO<=[=?]C=;NL<PP=;?K<`V=;NU=?cB=;NX=;O><MP=@<T<O=<?^<?^<@_=@SP=@SQ=@SR=@SS=@ST=@SU=@SV=@SW=@SX=@SY=@SZ=@S[=@S\\=@S]=@SQ=@SN=@O`=@>C=?<[=@MQ<RK=;KT<^C<KM=?S^<O\\=;Q^=;@P=;TS<QR=;OS<NL=@NX<cZ=;CR=@>_=@O:<B\\=;>A<]S=?<Z<\\A<YQ=@>V<`U<K]<`X<@:==ST=;OS<@d;Y<<Q;Z<=N;Y<=N;Z<<T;Z<=P=@Td=@U;;Z<;_<a;<NW=;LY<a]<>]<=Y=>TY<SY<CQ<a[=@NY<@d<@O<aR<>Z<Y;<@d=;LY=;Cd=@UQ<>S<=]<Td=;L?=@UU=@UC=@>U=>dW<RB=<@M=@T^=@T`=@Tb=@U?=@U<=@U>=@U:=@U<=@UB<A<=@UK<a\\=@U`=@UO=;P:=@>`=;MO=>U<=;NX=@UV<?C<UM<MP<@:==cU<A?<=U=@Rd=@S;=;O;=>^S=;PV=?>V=?cM<a<<@X=>TV<MP<SA=;R[<@^=@SN=@S^=@WC=@WK=@WL=@WM=@WN=@SZ=@S`=@OV==]N<?V==SB=?:[=;VK=?\\Q=?OT=>W?==V?=?bT=>[N=?__=>dO=>dB=>W@=>`O=?R==?:;=>W_=?_Q=@Mc=?;U=?[N=>KZ=<?A=<RV=@<;==;b=;>T=;YQ<A\\=?SO=<;U<A?=?[C=@M@=?KS=;cX<`N=;d@=?``=@Wa=>[T=@W]=@KQ<BN=?`L=;UY<AB=>XZ=;X<=?VB<WN=@X?=;\\?=;_==?MA=;]d<AB=?\\N==L?<A?=?_[=<CC=<?<=?Cb=;U[=?\\A=?XV=?MR=;VK=?Q[=;`b=@MY=?QV=@X[<LU=?Ka=?X]=;\\d=;YQ=?X]=>;?=?Q`=@@==;YQ=?RR=;YQ=<=?==d]=@YK=@Y^=;_L==W<<A\\<RK=;V==?`C=?KS=>aR=;a\\=;_V<W?=;_^=;ad=@M:=?:a=;`A=>V@=>[N<VK=>Yb<TW=@Z:=@W[=<LQ=@Z>==M>=@ZA<T>=>aR=<AT=@ZL=@ZS=@L[=>W[=<<[=@XO=>XS=@KQ=;X]=>XU=?dL=;U[=?TL=>dP=<B>=?`==@XX=?aY=@Mb==BB=@WZ=?B>=<?a=@Z?=@?W=@Z^=;[M==BQ=;[;=@L<=?:<=>[N=@NU=>[N<]K=;BT<ZL<OC<XU=?<\\=@>X=@TU<QU<ZQ<S<=@?P;\\=>c_=@QP=;?]<`X<Od<PM<=U<=Z<@]<=\\<=[<@Y<A=<VU<VW<??<_Q<a<=>c`=@\\T=;U^=@>[=@TN=@>^=;CT==?T<?V==[O=?aY=>dQ=@BL=?:N=@NQ=?:A=?OS=@X[=;Ub=;W\\=;U@=?BX<ON=;c[=@B:=<cc=;_S<C^=;XY==L[<BS=;W\\=@AX<A?=@]B=<Rc=?BX=<dW=;]a=;VC=<cd=?C\\==:^=;UO<BS==]<=<:_=@Qd=;Xd=?BX=>AK=?B[<AQ<?V<NO=?B_=;bZ=;`V=;_a=;bY=;]]=?Lb=;bW<AQ===\\=?C:=@YO=?Z:=@YL=?`b=?C;=<:b=?C_==;b=<<K=;W^<AQ=;U>=?MK=?ZK=@[N=;Zd<@:=;^Y<>C=@R\\=?>V=;QS<ab=@:B<dR=;OQ<@\\<L]<B`=;PA<VS<@[=;VP=?P<=<RY=@;K=<?T=?Z\\=>dc=@:\\==`>=?\\]=>`X=@:>=>Zb<VK<C:<>]=?b<<AC<>a=;K@<@:=<@==@_;<\\K<X?<d?=@_>=;CX=?a^=@_B=;KC=;KL<>T<@[=?YQ=?OM=<=W=<]^=;ac==?P==UC=?\\O=>`W=;_K=;^;=@XR=;^;=;W^=@`T=;U@=?QW=<CR=?aO=?N`=@L?=@XR=>`N=@`[=?NT=?`;=;[R=?V;==_X=;WW=>cQ=>W;=?OM=;]`=<[@=?OP=@M^=>YS=?;N=?;`=?OS=@_\\<PT=;LP=@_`<A?=@_b=;?V==?T=@`;<TQ=@_==;K@=@`@=@:C<d\\<@\\=;KO<^S=@_N=?Z@=@`O=<N:=?K`=>VC=?ZZ=;V[=>XB=@`V=?C@=?Ca=;_V=<:_=@X>=@];=;VQ=<d\\=;YT==S^==<M<^U=@``==L[==MR=@^\\=;X]=@bO=;:W=?B>=@a==?MA=<c^=@a@=?b^=@`U=?;U=?OO=>[N=@?Z=@YU=>dR=?;`=@NW<VQ<R?<B;=?\\><\\c<@C=;BT=>Pd<cP=@cN=;=^=@cP<c]<>A=?@R=@cN=<@Q=@cT<`c=;;><KK<Oa<?;<AN<O\\<@C<?^=?NC=>LN=?:L=;W?=<AT=@?U=<B>=@W^=?bP=?P>=@Wb=?_a=?U`=<d\\=@d==;bZ=@ZV=;[M=?OP=;^>==:;=>YC=>`T=?bM==[X=?[^=?`<=@YT=<BA=>Z^=@;T=?aS=?`Z=@MK=?XX=@Q^=;Y>=@cB=@R`<@:=;d@<@d=?]C<=U<>B<VB<Cc=;TS<`^=;MS<aW=;AM=;NC=>U==@Ud=?=d=;VX<=[=@TL<VQ=@>K=;VX<cR<YQ<>`<P]<?K<P_=??V=;U?=?]C=@TM=;<^=>d<=?^<=<N:=?[>=?K==<:N=>W^=;Zd=@@X=?\\N=<:_=?\\N=@RR==@X=;VU<ON=?Z:=;W^=@?b=;X]=?YU=;c<=?OQ=<[R=?Qa<AC=;\\`=?;S=<K[<AB=?[C=<:_=?[L=;X]=?_[=@X^=;\\?=;d\\=@X@==BB=?``=?RZ=@^P=A;W=?aV=;_V=?Bb<C^=?`==?R@=;]Z=@AT=@[]=;U?=<^b=@Bb=A;d=;VC=;Xd=?`==<>;=@AT=@<;=;X]=@C:==TC=;:W=?W]=<:_=?W]=;W^=>MR=<[R=@]Q=;VV==[<=;`C=@^C=A;W=?Y?=@BP=@bP=?XQ<UA<P[<C^=A<d=;_:=>MR=;W^=?MP=<CO=@]N=<`Z=@LP=<V:=A=;=<MY=;U<=@^B=@@[=;bY=@Zc=@BS=?V==@K`<NA=@L:=;UV=;`a=>V_=?Bd=?KS=A>==@LA=;YO=@K`=?N_=?PB=<=K<W<<UA=;W^=A>L=;_:=@C==>KZ=;`T=;dC==><=@Zc=?_?=<>O<O^=>X`=?BS=?CN<AC<O^=?aV=@Ba=A=B=?[C==L?<AB=?`L=@XR=?`L=@RU=?Lc=?;<=@<a=?U==@PO<W]==BK=@PS<R_=@PV<Rd<[Q=@PY<S?=@P\\<O\\=@P^<@]<>O<?L<BU<><<=W<@]<L^=;MK<B:=;;:=;MO<]`=@QC<OC<C==@==<`]<KM=;VP==\\A<`M=?bN=<_<=?_:=>a:=?:a=?:K=@aP=@?W=?\\Q=>P;=?ZN<AK=?:R<\\_=?:T<B;==UO=>:T<YK=@PT<R`<?@<Rb=A?P<S;<S==A?S=?P]=@P]<SM=A?]=;MC=@>N<?C<?C<RM<V[<TS=@QM=@QL<=]<Z[=>Ta=;MW<>S<=b<SS<T:<?;=@QO<?@=A@?=>V;=A@P==VN=A@K=?_`=@Q_=>dO=?:d=?[^=?\\^=A?@<[O=A@U==NA=A@W<@:=<PL=A?M=@PU=A@^=@PW=A?Q=A@b=@P[=A@d=A?U=AA;=A?^=AA>=AA@=?Ta<V\\=AAK<@]<AX<>T=AAV=AAX=A@A=AAZ=@Wd=?V==@a>=<?a=?OP=?;O=AAZ=?\\^=>cT<Pa=@P`<SR<Q<<B`<KK=;?C=?UR=@>X=;ML<PM<KW=AAK=;aC==CK=;Y;=>XU=>V]=?bV=;UZ<V^=?bY=>:d==PL=;X:=;Qd=?OK=<>O=A;\\=?:O=>b^=AC\\=;\\K=>dK=@M;=>c?=@Wa=@MQ<]K=A?C<>`<QQ<Wc<?><@:==@^=AB?=A@]=A@_=@PX=ABK<S@=ABM<SK=AA;=@VM<@]=;Ma=;Mc<C[<MR<?K<VZ<Ud<>\\<@]=AKU=@VM=AAV<_Q=;KX<L?=@\\A<?@=;YZ=@Yc=?bM=>[Y==VN=?aO=?B===M>=?VB=?dX=?`Z=?C==@^L=?:>=@Zc=?ZM=@;<=?;R=@L>=?OA=>YC=AC\\=?Zc=?\\^=@[N=>_c=@MQ=>d[=?;@<B;=@?R=AKL=A?O=AKO=@PZ=AKQ<SB=ABN=@<Z=AC<<B_<SS=;LT<SW<SY=@Q<=>T?=@Q>=@Q@<aX=@QB=AAT<@]=;S<<TS<S`=;N<<AM=;N>=AK\\<V\\=ABY<BN=A@@=AL?=?Zc=AB]==N@=AB_=@[[=@]?=?\\Q=A<Q=>dO=;ZN==]L=@[\\=@d`=ANA=AN=<NA=<;b=@RX=;<@=@RZ=;?T=@`<=>]W=@cC<`R=@V:<PZ<ZU=@TZ=AL:==a:=@V]=@V_=;OO=;NM=@S>=;Sc=@?C<KM<dd=>TV=@SC=?]C=@VM=@WB=@WO=AO?=AO@=AOA=AOB=@SP=@SN=?<Y=@>K=?;==>PS=@T;<Y<=@T=<OV=@T?=;BT=@SC=;OS<@:=<@Q=@V==@Ta=@Tc=@VC=@U==@V@=@UA<@d=>\\P<AO=;d>=@UZ<La<L?<dP=@V>=AO]=@U@=@VB=@U@=@UB=;KS=?MZ<P<<?==AOX<X_=AP;=A:`=;XS=@UV=A:R=>dX<AC<QA<Q;==KC=@V^=>QA=@S:=;OR=?aa=;CS=>\\C=ANd=?]K<MO<@d<A:=@VM<A:<O:<C=<M:<XM<]O<cR==]Y=AN\\=AP]=@V`=;B=<c?=@Vc<d?=@W:<@^=@W<=?c[=@W?=@<T=AO>=AOC=AQ[=AQ\\=AQ]=@SU=@SN==Ra=<`]=ANC=>YX=AMa=@?W=?`:==ZW=<;A=A@L=;bZ=?VB==VC=?VB=>aa=@XL=@ZS=?:>=@[Z<X_=?Q[<ON==Qd=;[S<Pa=;V==?VB=A<O=ALV=@;@=;Ub=;bO=@A[=;_S=?Y<==;b=;c;=;_:=;WC=;W^=AR\\=<d]=?B:==[U=@^Q==M>=@BB<YB=@L^=?Wa=@L=<BS=<:Q=@K`=;]]=;_b=?WV=<<L==V==?XQ=>WB<C^=A=S==d<=ASW=;\\`=A=W=?SO=;UO<K>=;X_=?K==AS_=A=R==<`=A=>=;_L<A><UA=<_X==><=A>;=?Xb=;bZ<O^=?XU<T>=@]_=A>^=@bP=@^X=;YK=A=[=?MA=;Xd<UA==<K==<d=@dS=@M==@Qb=@[=<AC==]<=@@X=<=N=>VC=AT^=<CO=@]L=;VV=<LQ=ARA==VN=ARC=>a@=>a;=@[P=?Lc=ARO=;UZ=@AQ=;Y@=;^d=?V@=?:^=;\\?=?;S=?Q[=@Z;=<>O=@XB==VC=@ZA=ARK<BS=<;b=@BK=>Z@=?Rd<`M=@ZU=@[O=>VQ=>cT=>]Z=@\\V=@\\X=AAV=@\\[=A@S=AM]=;U?=>Cc=@MK=?B;=AR@=?_P=?_d=?da=?B@=AR==@]:=?MT=?OR<A?=>;?<`N=?\\<=?b`=;U^==SR<>@=?=_=;?K=;KP<@d<`c=;:=<d[=??B=;OV<L`=;Kc<dL=?@><dM<ZX<Y<<cN<SB<`^<?@<?C=;S^=AVa=;:C=;?K=??>=?cB=@<T==NT<T<<]b=;O[=;Tb=;PB=?^V=AOb=?b==@R]=>A<=?b@==P=<`N<>L==>:=@_Q=>V^=?K]=?ZY=?K==?_?=@_Q=?^]=@R@=AX;=?d]=?\\U=AX?==d<=AX<=<;K=?dO=;a`=>VC=?N\\=?\\Y=?B<=ACR=AU?=?dZ<`N=>WQ<BN=@C:=@ZM=@dQ=@]>=@MY=?:K=@d@=ACd=?``=@dP=@dL=@Q\\=>VX=@YR=>W[=>[K=;V?=<?a=@@C=ACT=@X;=?L\\=@;A=@:?=>L^=?P@=>[[<AC=?b`=?T><B;==ST<d=<P<<d?=?>K<dC<>c<dL=>U=<B`<`==>T==AMC=?@S<NW=;TO<dM<?@=;>b<?=<LZ=?>K=AWA=;O_<`@<B^<K;<Y<=;:@=?T[=??Z=?TX=>BA=??X=AZN=;:K=?T]=;QV<?:=?T_=??a<V[=;WS=@V\\=ANA=;[X=;Y^=?_:=AZ_=?`[=AZa=?VM=>bb=@XY=<@@=<;K=?CT=>@@=?[a=?b]=A?>=;^P<V_=?\\a=?M_=A?A=@MR=AB<==]C=ALc=ABA=A@`=A?R=ABL=AM==AKS=AM?=>\\S=@Pb=AYa=@Q:<SZ=;TO=AMO<Sa=AMQ<S`=AMS=AAT=AAV<W_=AX>=<:N=<:_=?^`=?dT=?`?=;\\C=<;?=?ZB=>YO=ATb=;[S=?:c=A;W=>`b=@dU=;XK=?\\<=?M?=;CV=?aa=;PR<OB=?^<=;S?<TV=AX>=AWd=<[O=<:b=@`T=A<<=?dR==^Q=ALZ=?\\:=<?_=?OU<@<<Pa<@:=;bC=;CW<AW=;CP=?c[=;PY=?Pd=;VX=@<`<A?=AKb=?Mc=AZA=?=K=AQB<Kc<cR=>S==;KR<RK=@OZ=AWW<?;=A:b=?YN=>\\U<`c=?@O<ac=;O_=@cb=APV<K;=>CZ=AWb==QR=;_S=>VC=@_U=>XW=A;@=;X:=?dY<BN==U:<`M=>V\\=;VV=AY:=?:]=AR?=>\\>=;]`=A@N=AXd=<CT=<?a=?_W=?[M=?K==?RV=?Zc=@RR=ALM=AR==>P?=?bM=@;O=?YS=AYB=?:<=?LZ=AYL=>dM=A<B=<RK=@;V=?Y]=>AR=?RN=A_O=>VN=?BL<?V<K>=@Y>=AU]=@c<=;[S=;ZN=?O<=@ZV=A<d=@@>=;Y;<;U=;[S=ARS<LB=@Zc=?RC=?d`=?ZB=A\\O=>dM=A_[=@bc=>PB=;VC==]C=@aQ=>b]=@[C=@WY=@[C=ANK=;`[<V_=A]B=?aa=A]K=;?<<MP=A]N<`K=AWR=AL;=;=V=A\\Y=@OB<c<=A]W=A`Y=AYS<@:=>C==?TA=AYY=AW;=AYY=?@A<dM<X\\<Q?=>U;=A^:=;CP=AZM<A?=;M?<C;=AZP==XY=AZR=AaM=?T\\=ANN=??^=;:]=?T`<V[=<aa=A^@=AYQ=@@d=A^B=?\\O=A^L=@_W=@;B=<cO=>[N=A^S=;_L=>K;=@d?=AM`=AMd=?:O=ACU=A@O=;VS=@@<=;VL=;cP=<:_=>Vd=?[U=;cQ=@d^=;_A=;\\?=A_;<NA=?Z]=;Ub=;ZV=;<?=?KK=;XA=AZd=;Z@=;:W=?Lb=Ab^=;]a=?WM=;]S=ARP=;_T=AYK=ACX=@;C<`M=@@M=A[<=;[X=Ac><YQ=?CT=;:W<UA<V^=@RT=@<L=?YX=A[L=;:b=;LS<\\V=;PZ=A]^=A:b<VK=@\\K<>d=@\\M=@\\O=@\\Q=@\\S=@?L=?b>=@=c=AW]=>[N<`Q=??]=AZW=;d>=A`]=Aa@=;QZ=>Q=<R<<b>=<<P=A\\==Aa]=A\\@=A=]=A\\B<BN=>>T=@W^=>Y`=A\\S=@WX=AA^=>`Y=<B>=?BL=?L<=@?X=;[]=ACc<LB=;]]=;WW=A^Y=@dM=<?a=;V<=@?W=AY?=?`a==bY=Ac:=?bX=@;>=@;==@XX=>bL=?V>=<]T=;VL=AX>=?SC=>XN=@@]=<:_=>>B=?_@=@b^=;XA==<^=?aW=AcQ=@_S<A@=A`b=AYU<d>=?TB=AYZ=AY\\=?aa=AY^<N^=AY`=@Pd=>T]=;LV=>T?=AZ:=AZ<=AZ><bL=A`U<?;=AZB=;B=<Qb=AaL=;@==??T=AaP=;:O=?TZ=AaS=??Z=AZU==V;=AZW=AaW=AZY<TQ=AZ[=@W_=>a==AZa=<<K=AZa=?Qa=AZc=?S==A_?==Ub=@@M=A[>=;_S=A[@=AYO=>XW=<;;=A[K=?TY=AL^=?;?=@MT<W]=A[Q=A@[=A?N=A[S=AM:=A@c=A[W=A?V=AM@=A[[=B;==@Q;=A[_<C>=AMP<Sc=A[d=@QK=AAV<X<=AXN=?C]=<AL=?_R=A\\C=@];=A\\M=AC]=A;W=AbR=>YU=A\\S=@aA=AL\\=;VL=A]@=A:[=A:]=A:_<Pa=?]N=;BX==^]=;OL=;>L<bV=?<c<M:=>^W=;>S=?===;>W=?=@=>^_=?=C=>^a=?=M=>U:<[Q<a:<aW<aY=?>N=?=^<d:=>T<<[Y=>TY<ZZ=;CA<Z^=;K:=;?R=?YN=;Cd<Z`=AaN<?;=;R`<]`<>C<?K<AL<Xb=;@P<C;<PQ<B;==^Z=?d:=;Q@=;Cd=B>O<d`=B>U=;QC=>^V=;;?<P=<L`=?@`=;O;=;L>=??B=;Q?=>^K=?AC=AW@<TP<d\\=?@W<dP=B?;=;Cb=A:\\=;QA=;K:=AWQ<X<=;BA<UV=B>`=;@Y<@:=?<`=@?C<d\\=B?W=B>P=B?Z<Z`<@d=B?^=;;N=B?C<dB<cb=B?M<CN=;NX=>U==@R`<C==B?S=?>W=B?V=;Ca=B@<=B?><QT=B?N<OK=B?P<@^==<P=?Z]=@`P=B=Q=<?T=@^^=<CO=AAa=@b<=@;U=<>^=@;c=@`b=@<C=?_R=ACQ=;XA=;]`=?\\N=;]]=AbU=?O\\=@XS=?[K=?K==?_[=B:V=<SS=>WK=;U@=;]V=;^<=Ac:=>[U=>[N==B>=>LY=?`_=AX^=?Ad=?R==AbC=@ZV=?W]=?_@=>d<==PW=;W?=;VC=AdU=A[;=@d_=AN<=BA`=@Zc=BB?=B:[=;ZW=>Rd=B>Y<?L=?QP=>_Z<`N=@LQ=@;Q=@[S=<aP=>NU=>VC=?\\N=?`W==:X=?Z`=B:Z=A]><@<=@NW=B=S<P^<P`<ZU=?^U<Q;==\\d=?<a=B=\\=@NK=>^V=?=:=>^X=B@B=;>V=?=?=>^X=?=A=>^`=;>`=B><<KS=AaB=B>@<ba=B>B=>_==>T<=?^@=B=W<C;=;?R=;d>=;QM<SC=;CX=??N=@`?=;CL=B?B=A:<=@TA=;QN<d\\=;QP<>c=;QR=@a^=B@@=;;@<@^=>aO=AVS=A^R=?Zc=?Y]=A;Q=@?a=@YK=B@d=?aL=;c>=<c<=;^_=?_<=@bL=AXC=@RK=AbQ=?MA=BAK=A^P=?`Z=B@^=A;<=AXO=?K==?N\\=;W^=AbO=@RQ=<XS=?;U=@<B=;W^=?W==BB:=BK_=@CP=BB_=AL\\=@Md==K@=?PP=;QZ=;RZ<NW=BK:=?Pd==PO=BLT<N?=;Q[<]O<NW=BKK=B?B=;`^=BKO=AbV=>[L=?Y]=B@b==d<=BM<=AbP=;_L=BLA=@:]=?`c=;W^=A;U=BM?==QP=A`<=AcP=A]>=?;d=<;b=;SX<=]<=Y=;S\\=A@:<>Z<=Y<KB<R[<UU=?d<=>bS=@>T==US<[\\=>SL<@d<>@<?K=@TL<]b<><=BMb=?>N=;RP=@>T<YQ=BN:<B]=AaR==BT=?\\?<^L<_^=;@<<AU<>]<SU=;Qa<VT<YQ=;SN<Qb=;BT=?U:=@NC=;<^<]K=;CW=;C<<KL<LL=;OC=;RU=;NY<^S<N==>^V=AA?=;@Y=;N\\=BO:=>^W=ACA=;CQ<X<=;CW<ZK=;::=;:P=;bC=BNS<M;=;=B<`^<>M<N=<>\\<]^<?><QU=BOM=?aa=@U_<AW=;LP=BOA==C?=;LP=?ab=@P@<C=<V?=;OK=BOS=;=`<UM=B?==;A@=A[M=AAd=@<b=A@V=AL`<@:==B><A?=A[R=AKN=ABC=AM;=A?T=A[X=@P_=A[Z=AMB=B<]=A[^=@Q==B<`=A[a=B<b=@QK=AMT=AAB<TT=BMT<Ub<CW=BMX=AM[<TS=AAV=<MV=<VX=B;`=A`P=;Zd=;`T=?ZM=;Z_=AZb=;[M=?:@=?_K=@bP=BQO=;[M=Ab`=;[M=@]N=BQT=A`:=BBN==C`=AcM=;[S=BQP=?B]=BQP=?Lb=BQT=A=`=AZa=@BU==C`=BK[=?CB=>`P=BQ`=<?a=@C?=AZa<K`=BR@=;a`=BRN=;V@=BRN<ZT<AB=;a\\=AAa==aS=?bN=<;b=AB]=@Lb=;[;=?YQ=AB`=AA_=BA_=A@Q=>dO=;]`=@_Q<@===QC=A@P=@:>=Ab@=Aa_<`M=BS;=>M>=BS==ALT=BRd=BSA==Ub=@:>=AYR=?>><[V=<`C=Aa:=?@=<aZ=B:a=Aa>=>U=<LQ=;>Z=?@Q=?>^=A[]=>U<=>QA=B;Q=B>W=B;T=BNM=B>W=B;Y=AaV=;@P=AaX<TQ=;`T=AZ\\=@aQ=AZ^=AR;=BR>=BQQ=@?_=B<<=;ZW==@\\=Ac@=@;:=?SM=A[?=?\\\\=>\\<=AYP=AcB=;Y>=AcS=A]Z<RO=AaU=AZW=@cS<ZZ<d\\=AdB<`C<@^<]b=AXN=;^;=<:_=;^;=@;\\=ACS=BTP=>bd=>[N=BLC=;X]=>`N=AXN=>`N=?M:=BUM=BA@=BK_=;Ub=BMP=B<K=@ML<RK<]X<?L<]Z<OC<]]<]_<]a<Ab<U^<U`<^<<^><B_=>PP<NP=>[_=;VC==X?=@NO=>YC=@]==@]?=>;T=BS>=A[A=@dB=?\\Q=@NW=B?]<Vb<SA=B>a=>[^=>cC=BV<=?PU=@N^==ZU=;=a=@Nb=;=d=@Nd<>`=<cA=@Y_=?ZV==NO=?K:=<:_=?K:=@R:=;U[<;Y=<:\\=?[?=>b^=BRV=ALZ=@X;=;_T=BRA==?P=>Vb=BLM=>AK=@Q\\=@RT=?Z]=@Ya<W<=@RN=;W^=@Qd=?N\\=;X:=A]<=BRc=?Ac=<Cb<W<=?SC==d<=BWb=AbW=;U[=?[Q==Ub=@RT=BW[<BN=A]<=>cL=>:Z=BAT=>dN=?_T==A:=?Y]=BW<=?W^=?`?=<dS=<:\\<ON=;Z@==A:<PA=A\\U");
    local e, d, l, A = 1, V and V.bxor or function(e, l)
        local A, d = 1, 0;
        while e > 0 and l > 0 do
            local a, c = e % 2, l % 2;
            if a ~= c then
                d = d + A; 
            end;
            e, l, A = ((e - a)) / 2,((l - c)) / 2,A * 2; 
        end;
        if e < l then
            e = l; 
        end;
        while e > 0 do
            local l = e % 2;
            if l > 0 then
                d = d + A; 
            end;
            e, A = ((e - l)) / 2,A * 2; 
        end;
        return d; 
    end, 219, function(l, e, A)
        if A then
            local e = (l / 2 ^ ((e - 1))) % 2 ^ (((A - 1) - ((e - 1)) + 1));
            return e - e % 1;
        else
            local e = 2 ^ ((e - 1));
            return (l % ((e + e)) >= e) and 1 or 0; 
        end; 
    end;
    local l, B, o = function()
        local n, c, a, A = a(C, e, e + 3);
        n, c, a, A = d(n, l),d(c, l),d(a, l),d(A, l);
        e = e + 4;
        return (A * 16777216) + (a * 65536) + (c * 256) + n; 
    end, function()
        local l = d(a(C, e, e), l);
        e = e + 1;
        return l; 
    end, function()
        local c, A = a(C, e, e + 2);
        c, A = d(c, l),d(A, l);
        e = e + 2;
        return (A * 256) + c; 
    end;
    local function V()
        local e = l();
        local l = l();
        local c = 1;
        local d = (A(l, 1, 20) * (2 ^ 32)) + e;
        local e = A(l, 21, 31);
        local l = (((-1)) ^ A(l, 32));
        if (e == 0) then
            if (d == 0) then
                return l * 0;
            else
                e = 1;
                c = 0; 
            end;
        elseif (e == 2047) then
            return (d == 0) and (l * (1 / 0)) or (l * (0 / 0)); 
        end;
        return L(l, e - 1023) * ((c + (d / (2 ^ 52)))); 
    end;
    local e, c = l, function(A)
        local n;
        if (not A) then
            A = l();
            if (A == 0) then
                return ''; 
            end; 
        end;
        n = c(C, e, e + A - 1);
        e = e + A;
        local l = {};
        for e = 1, #n do
            l[e] = N(d(a(c(n, e, e)), 219)); 
        end;
        return W(l); 
    end;
    local e, W = l, function(...)
        return {
            ...
        },  X('#', ...); 
    end;
    local function O()
        local N, n, e = {}, {}, {};
        local C = {
            N,
            n,
            nil,
            e
        };
        local e, d = l(), {};
        for A = 1, e do
            local l, e = B();
            if (l == 1) then
                e = (B() ~= 0);
            elseif (l == 0) then
                e = V();
            elseif (l == 3) then
                e = c(); 
            end;
            d[A] = e; 
        end;
        for n = 1, l() do
            local e = B();
            if (A(e, 1, 1) == 0) then
                local c, a, e = A(e, 2, 3), A(e, 4, 6), {
                    o(),
                    o(),
                    nil,
                    nil
                };
                if (c == 0) then
                    e[3] = o();
                    e[4] = o();
                elseif (c == 1) then
                    e[3] = l();
                elseif (c == 2) then
                    e[3] = l() - (2 ^ 16);
                elseif (c == 3) then
                    e[3] = l() - (2 ^ 16);
                    e[4] = o(); 
                end;
                if (A(a, 1, 1) == 1) then
                    e[2] = d[e[2]]; 
                end;
                if (A(a, 2, 2) == 1) then
                    e[3] = d[e[3]]; 
                end;
                if (A(a, 3, 3) == 1) then
                    e[4] = d[e[4]]; 
                end;
                N[n] = e; 
            end; 
        end;
        for e = 1, l() do
            n[e - 1] = O(); 
        end;
        C[3] = B();
        return C; 
    end;
    local function L(e, o, B)
        local l, e, A = e[1], e[2], e[3];
        return function(...)
            local d, W, c, C, l, a, X, K, N, V, A = l, e, A, W, 1, -1, {}, {
                ...
            }, X('#', ...) - 1, {}, {};
            for e = 0, N do
                if (e >= c) then
                    X[e - c] = K[e + 1];
                else
                    A[e] = K[e + 1]; 
                end; 
            end;
            local K = N - c + 1;
            local e;
            local c;
            while true do
                e = d[l];
                c = e[1];
                if c <= 117 then
                    if c <= 58 then
                        if c <= 28 then
                            if c <= 13 then
                                if c <= 6 then
                                    if c <= 2 then
                                        if c <= 0 then
                                            if (A[e[2]] ~= A[e[4]]) then
                                                l = l + 1;
                                            else
                                                l = e[3]; 
                                            end;
                                        elseif c > 1 then
                                            local c;
                                            local a;
                                            local n;
                                            A[e[2]] = A[e[3]];
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = e[3];
                                            l = l + 1;
                                            e = d[l];
                                            n = e[3];
                                            a = A[n];
                                            for e = n + 1, e[4] do
                                                a = a .. A[e]; 
                                            end;
                                            A[e[2]] = a;
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = {};
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = e[3];
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = B[e[3]];
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = A[e[3]][e[4]];
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = e[3];
                                            l = l + 1;
                                            e = d[l];
                                            c = e[2];
                                            A[c] = A[c](A[c + 1]);
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = A[e[3]][e[4]];
                                        else
                                            local c;
                                            local a;
                                            local n;
                                            A[e[2]] = e[3];
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = o[e[3]];
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = e[3];
                                            l = l + 1;
                                            e = d[l];
                                            n = e[3];
                                            a = A[n];
                                            for e = n + 1, e[4] do
                                                a = a .. A[e]; 
                                            end;
                                            A[e[2]] = a;
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = o[e[3]];
                                            l = l + 1;
                                            e = d[l];
                                            A[e[2]] = A[e[3]];
                                            l = l + 1;
                                            e = d[l];
                                            c = e[2];
                                            A[c] = A[c](A[c + 1]);
                                            l = l + 1;
                                            e = d[l];
                                            if A[e[2]] then
                                                l = l + 1;
                                            else
                                                l = e[3]; 
                                            end; 
                                        end;
                                    elseif c <= 4 then
                                        if c > 3 then
                                            A[e[2]] = e[3];
                                        else
                                            A[e[2]] = (e[3] ~= 0); 
                                        end;
                                    elseif c > 5 then
                                        local l = e[2];
                                        do
                                            return A[l](n(A, l + 1, e[3])); 
                                        end;
                                    else
                                        A[e[2]] = L(W[e[3]], nil, B); 
                                    end;
                                elseif c <= 9 then
                                    if c <= 7 then
                                        local l = e[2];
                                        local d = A[l];
                                        for e = l + 1, e[3] do
                                            M(d, A[e]); 
                                        end;
                                    elseif c == 8 then
                                        local e = e[2];
                                        local d, l = C(A[e](n(A, e + 1, a)));
                                        a = l + e - 1;
                                        local l = 0;
                                        for e = e, a do
                                            l = l + 1;
                                            A[e] = d[l]; 
                                        end;
                                    else
                                        A[e[2]] = A[e[3]]; 
                                    end;
                                elseif c <= 11 then
                                    if c > 10 then
                                        local N;
                                        local V, X;
                                        local o;
                                        local c;
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        o = A[e[3]];
                                        A[c + 1] = o;
                                        A[c] = o[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        V, X = C(A[c](n(A, c + 1, e[3])));
                                        a = X + c - 1;
                                        N = 0;
                                        for e = c, a do
                                            N = N + 1;
                                            A[e] = V[N]; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](n(A, c + 1, a));
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        o = A[e[3]];
                                        A[c + 1] = o;
                                        A[c] = o[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                    else
                                        local a;
                                        local c;
                                        local n;
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        n = e[3];
                                        c = A[n];
                                        for e = n + 1, e[4] do
                                            c = c .. A[e]; 
                                        end;
                                        A[e[2]] = c;
                                        l = l + 1;
                                        e = d[l];
                                        a = e[2];
                                        A[a](A[a + 1]);
                                        l = l + 1;
                                        e = d[l];
                                        l = e[3]; 
                                    end;
                                elseif c == 12 then
                                    local e = e[2];
                                    A[e] = A[e](n(A, e + 1, a));
                                else
                                    local n, a;
                                    local c;
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    n, a = {
                                        A[c](A[c + 1])
                                    },0;
                                    for e = c, e[4] do
                                        a = a + 1;
                                        A[e] = n[a]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    l = e[3]; 
                                end;
                            elseif c <= 20 then
                                if c <= 16 then
                                    if c <= 14 then
                                        local a;
                                        local c;
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        a = A[e[3]];
                                        A[c + 1] = a;
                                        A[c] = a[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c](A[c + 1]);
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = (e[3] ~= 0);
                                    elseif c > 15 then
                                        local d = A[e[4]];
                                        if not d then
                                            l = l + 1;
                                        else
                                            A[e[2]] = d;
                                            l = e[3]; 
                                        end;
                                    else
                                        A[e[2]] = {};
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4]; 
                                    end;
                                elseif c <= 18 then
                                    if c > 17 then
                                        local a = e[2];
                                        local d = {};
                                        for e = 1, #V do
                                            local e = V[e];
                                            for l = 0, #e do
                                                local e = e[l];
                                                local c = e[1];
                                                local l = e[2];
                                                if c == A and l >= a then
                                                    d[l] = c[l];
                                                    e[1] = d; 
                                                end; 
                                            end; 
                                        end;
                                    else
                                        for e = e[2], e[3] do
                                            A[e] = nil; 
                                        end; 
                                    end;
                                elseif c == 19 then
                                    do
                                        return A[e[2]]; 
                                    end;
                                else
                                    local e = e[2];
                                    A[e] = A[e](A[e + 1]); 
                                end;
                            elseif c <= 24 then
                                if c <= 22 then
                                    if c == 21 then
                                        local e = e[2];
                                        local d, l = C(A[e](A[e + 1]));
                                        a = l + e - 1;
                                        local l = 0;
                                        for e = e, a do
                                            l = l + 1;
                                            A[e] = d[l]; 
                                        end;
                                    else
                                        local c;
                                        c = e[2];
                                        A[c] = A[c](n(A, c + 1, e[3]));
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        do
                                            return; 
                                        end; 
                                    end;
                                elseif c == 23 then
                                    local a;
                                    local c;
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = A[e[3]];
                                    A[c + 1] = a;
                                    A[c] = a[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                else
                                    local a;
                                    local n;
                                    local c;
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    n = e[3];
                                    a = A[n];
                                    for e = n + 1, e[4] do
                                        a = a .. A[e]; 
                                    end;
                                    A[e[2]] = a;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    if (A[e[2]] ~= e[4]) then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end; 
                                end;
                            elseif c <= 26 then
                                if c == 25 then
                                    local c;
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return; 
                                    end;
                                else
                                    local n, c;
                                    local a;
                                    o[e[3]] = A[e[2]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[2];
                                    n, c = {
                                        A[a](A[a + 1])
                                    },0;
                                    for e = a, e[4] do
                                        c = c + 1;
                                        A[e] = n[c]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    l = e[3]; 
                                end;
                            elseif c == 27 then
                                local a;
                                local c;
                                local o;
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                o = e[3];
                                c = A[o];
                                for e = o + 1, e[4] do
                                    c = c .. A[e]; 
                                end;
                                A[e[2]] = c;
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                a = e[2];
                                A[a](n(A, a + 1, e[3]));
                            else
                                if (A[e[2]] == A[e[4]]) then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end; 
                            end;
                        elseif c <= 43 then
                            if c <= 35 then
                                if c <= 31 then
                                    if c <= 29 then
                                        local X;
                                        local V;
                                        local W, L;
                                        local N;
                                        local c;
                                        c = e[2];
                                        A[c](A[c + 1]);
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        N = A[e[3]];
                                        A[c + 1] = N;
                                        A[c] = N[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        W, L = C(A[c](n(A, c + 1, e[3])));
                                        a = L + c - 1;
                                        V = 0;
                                        for e = c, a do
                                            V = V + 1;
                                            A[e] = W[V]; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](n(A, c + 1, a));
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        N = A[e[3]];
                                        A[c + 1] = N;
                                        A[c] = N[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = {};
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](A[c + 1]);
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        N = e[3];
                                        X = A[N];
                                        for e = N + 1, e[4] do
                                            X = X .. A[e]; 
                                        end;
                                        A[e[2]] = X;
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = A[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = A[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        if not A[e[2]] then
                                            l = l + 1;
                                        else
                                            l = e[3]; 
                                        end;
                                    elseif c == 30 then
                                        A[e[2]][e[3]] = e[4];
                                    else
                                        local l = e[2];
                                        A[l](n(A, l + 1, e[3])); 
                                    end;
                                elseif c <= 33 then
                                    if c == 32 then
                                        local e = e[2];
                                        A[e](n(A, e + 1, a));
                                    else
                                        local o;
                                        local B, N;
                                        local c;
                                        A[e[2]] = A[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        B, N = C(A[c](A[c + 1]));
                                        a = N + c - 1;
                                        o = 0;
                                        for e = c, a do
                                            o = o + 1;
                                            A[e] = B[o]; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](n(A, c + 1, a));
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]]; 
                                    end;
                                elseif c > 34 then
                                    local c;
                                    local a;
                                    local n;
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    n = e[3];
                                    a = A[n];
                                    for e = n + 1, e[4] do
                                        a = a .. A[e]; 
                                    end;
                                    A[e[2]] = a;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    if not A[e[2]] then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end;
                                else
                                    local n = W[e[3]];
                                    local a;
                                    local c = {};
                                    a = _({}, {
                                        __index = function(l, e)
                                        local e = c[e];
                                        return e[1][e[2]]; 
                                    end,
                                        __newindex = function(A, e, l)
                                        local e = c[e];
                                        e[1][e[2]] = l; 
                                    end
                                    });
                                    for a = 1, e[4] do
                                        l = l + 1;
                                        local e = d[l];
                                        if e[1] == 9 then
                                            c[a - 1] = {
                                                A,
                                                e[3]
                                            };
                                        else
                                            c[a - 1] = {
                                                o,
                                                e[3]
                                            }; 
                                        end;
                                        V[#V + 1] = c; 
                                    end;
                                    A[e[2]] = L(n, a, B); 
                                end;
                            elseif c <= 39 then
                                if c <= 37 then
                                    if c == 36 then
                                        local o;
                                        local N, V;
                                        local c;
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c]();
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]] - A[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        N, V = C(A[c](n(A, c + 1, e[3])));
                                        a = V + c - 1;
                                        o = 0;
                                        for e = c, a do
                                            o = o + 1;
                                            A[e] = N[o]; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c](n(A, c + 1, a));
                                        l = l + 1;
                                        e = d[l];
                                        do
                                            return; 
                                        end;
                                    else
                                        local c;
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](n(A, c + 1, e[3]));
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        if not A[e[2]] then
                                            l = l + 1;
                                        else
                                            l = e[3]; 
                                        end; 
                                    end;
                                elseif c == 38 then
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = {};
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                else
                                    local X;
                                    local o;
                                    local N, V;
                                    local c;
                                    c = e[2];
                                    N, V = C(A[c](n(A, c + 1, e[3])));
                                    a = V + c - 1;
                                    o = 0;
                                    for e = c, a do
                                        o = o + 1;
                                        A[e] = N[o]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    X = A[e[3]];
                                    A[c + 1] = X;
                                    A[c] = X[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    N, V = C(A[c](n(A, c + 1, e[3])));
                                    a = V + c - 1;
                                    o = 0;
                                    for e = c, a do
                                        o = o + 1;
                                        A[e] = N[o]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]]; 
                                end;
                            elseif c <= 41 then
                                if c == 40 then
                                    local c;
                                    local a;
                                    local n;
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    n = e[3];
                                    a = A[n];
                                    for e = n + 1, e[4] do
                                        a = a .. A[e]; 
                                    end;
                                    A[e[2]] = a;
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    if not A[e[2]] then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end;
                                else
                                    A[e[2]] = e[3]; 
                                end;
                            elseif c > 42 then
                                local l = e[2];
                                local c, d = {
                                    A[l](n(A, l + 1, a))
                                }, 0;
                                for e = l, e[4] do
                                    d = d + 1;
                                    A[e] = c[d]; 
                                end;
                            else
                                local c;
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](n(A, c + 1, e[3])); 
                            end;
                        elseif c <= 50 then
                            if c <= 46 then
                                if c <= 44 then
                                    local e = e[2];
                                    A[e](A[e + 1]);
                                elseif c == 45 then
                                    local c;
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = A[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                else
                                    A[e[2]] = (not A[e[3]]); 
                                end;
                            elseif c <= 48 then
                                if c == 47 then
                                    A[e[2]] = A[e[3]][A[e[4]]];
                                else
                                    if A[e[2]] then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end; 
                                end;
                            elseif c > 49 then
                                local o;
                                local B, N;
                                local c;
                                c = e[2];
                                B, N = C(A[c](A[c + 1]));
                                a = N + c - 1;
                                o = 0;
                                for e = c, a do
                                    o = o + 1;
                                    A[e] = B[o]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = (e[3] ~= 0);
                                l = l + 1;
                                e = d[l];
                                do
                                    return A[e[2]]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end;
                            else
                                local d = e[2];
                                local l = A[e[3]];
                                A[d + 1] = l;
                                A[d] = l[e[4]]; 
                            end;
                        elseif c <= 54 then
                            if c <= 52 then
                                if c > 51 then
                                    local a;
                                    local n;
                                    local c;
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    n = e[3];
                                    a = A[n];
                                    for e = n + 1, e[4] do
                                        a = a .. A[e]; 
                                    end;
                                    A[e[2]] = a;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = {};
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                else
                                    local a;
                                    local c;
                                    c = e[2];
                                    A[c](n(A, c + 1, e[3]));
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = A[e[3]];
                                    A[c + 1] = a;
                                    A[c] = a[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, e[3]));
                                    l = l + 1;
                                    e = d[l];
                                    if A[e[2]] then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end; 
                                end;
                            elseif c > 53 then
                                local c;
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                l = e[3];
                            else
                                local N;
                                local L, X;
                                local V;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V = A[e[3]];
                                A[c + 1] = V;
                                A[c] = V[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                L, X = C(A[c](n(A, c + 1, e[3])));
                                a = X + c - 1;
                                N = 0;
                                for e = c, a do
                                    N = N + 1;
                                    A[e] = L[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                A[e[2]]();
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c <= 56 then
                            if c > 55 then
                                local c, c;
                                local L;
                                local N;
                                local V, X;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]]();
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c]();
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = (e[3] ~= 0);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V, X = C(A[c](n(A, c + 1, e[3])));
                                a = X + c - 1;
                                N = 0;
                                for e = c, a do
                                    N = N + 1;
                                    A[e] = V[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                L = A[e[3]];
                                A[c + 1] = L;
                                A[c] = L[e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V, X = C(A[c](A[c + 1]));
                                a = X + c - 1;
                                N = 0;
                                for e = c, a do
                                    N = N + 1;
                                    A[e] = V[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V, N = {
                                    A[c](n(A, c + 1, a))
                                },0;
                                for e = c, e[4] do
                                    N = N + 1;
                                    A[e] = V[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                l = e[3];
                            else
                                A[e[2]] = A[e[3]]; 
                            end;
                        elseif c == 57 then
                            A[e[2]][e[3]] = A[e[4]];
                        else
                            local V;
                            local X;
                            local L, W;
                            local N;
                            local c;
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            L, W = C(A[c](n(A, c + 1, e[3])));
                            a = W + c - 1;
                            X = 0;
                            for e = c, a do
                                X = X + 1;
                                A[e] = L[X]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            N = e[3];
                            V = A[N];
                            for e = N + 1, e[4] do
                                V = V .. A[e]; 
                            end;
                            A[e[2]] = V;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            do
                                return A[e[2]](); 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            do
                                return n(A, c, a); 
                            end;
                            l = l + 1;
                            e = d[l];
                            do
                                return; 
                            end; 
                        end;
                    elseif c <= 87 then
                        if c <= 72 then
                            if c <= 65 then
                                if c <= 61 then
                                    if c <= 59 then
                                        local N;
                                        local L, X;
                                        local V;
                                        local c;
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](A[c + 1]);
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        V = A[e[3]];
                                        A[c + 1] = V;
                                        A[c] = V[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        L, X = C(A[c](n(A, c + 1, e[3])));
                                        a = X + c - 1;
                                        N = 0;
                                        for e = c, a do
                                            N = N + 1;
                                            A[e] = L[N]; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](n(A, c + 1, a));
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = A[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                    elseif c == 60 then
                                        A[e[2]] = #A[e[3]];
                                    else
                                        local c;
                                        local a;
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]]();
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        a = e[2];
                                        c = A[e[3]];
                                        A[a + 1] = c;
                                        A[a] = c[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = {};
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        c = A[e[4]];
                                        if not c then
                                            l = l + 1;
                                        else
                                            A[e[2]] = c;
                                            l = e[3]; 
                                        end; 
                                    end;
                                elseif c <= 63 then
                                    if c == 62 then
                                        local c;
                                        c = e[2];
                                        A[c](n(A, c + 1, e[3]));
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                    else
                                        local N;
                                        local X, V;
                                        local c;
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c]();
                                        l = l + 1;
                                        e = d[l];
                                        o[e[3]] = A[e[2]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]] - A[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        o[e[3]] = A[e[2]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        X, V = C(A[c](n(A, c + 1, e[3])));
                                        a = V + c - 1;
                                        N = 0;
                                        for e = c, a do
                                            N = N + 1;
                                            A[e] = X[N]; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c](n(A, c + 1, a));
                                        l = l + 1;
                                        e = d[l];
                                        do
                                            return; 
                                        end; 
                                    end;
                                elseif c == 64 then
                                    local c;
                                    local a;
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[3];
                                    c = A[a];
                                    for e = a + 1, e[4] do
                                        c = c .. A[e]; 
                                    end;
                                    A[e[2]] = c;
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[3];
                                    c = A[a];
                                    for e = a + 1, e[4] do
                                        c = c .. A[e]; 
                                    end;
                                    A[e[2]] = c;
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[3];
                                    c = A[a];
                                    for e = a + 1, e[4] do
                                        c = c .. A[e]; 
                                    end;
                                    A[e[2]] = c;
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                else
                                    local o;
                                    local N, V;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    N, V = C(A[c](n(A, c + 1, e[3])));
                                    a = V + c - 1;
                                    o = 0;
                                    for e = c, a do
                                        o = o + 1;
                                        A[e] = N[o]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](n(A, c + 1, a)); 
                                end;
                            elseif c <= 68 then
                                if c <= 66 then
                                    local N;
                                    local L, X;
                                    local V;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    V = A[e[3]];
                                    A[c + 1] = V;
                                    A[c] = V[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    L, X = C(A[c](n(A, c + 1, e[3])));
                                    a = X + c - 1;
                                    N = 0;
                                    for e = c, a do
                                        N = N + 1;
                                        A[e] = L[N]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    for e = e[2], e[3] do
                                        A[e] = nil; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                elseif c > 67 then
                                    local c;
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = A[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                else
                                    local C;
                                    local c;
                                    local a;
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[3];
                                    c = A[a];
                                    for e = a + 1, e[4] do
                                        c = c .. A[e]; 
                                    end;
                                    A[e[2]] = c;
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    C = e[2];
                                    A[C](n(A, C + 1, e[3]));
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[3];
                                    c = A[a];
                                    for e = a + 1, e[4] do
                                        c = c .. A[e]; 
                                    end;
                                    A[e[2]] = c;
                                    l = l + 1;
                                    e = d[l];
                                    C = e[2];
                                    A[C](A[C + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3]; 
                                end;
                            elseif c <= 70 then
                                if c > 69 then
                                    if (A[e[2]] == A[e[4]]) then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end;
                                else
                                    A[e[2]][A[e[3]]] = A[e[4]]; 
                                end;
                            elseif c == 71 then
                                do
                                    return; 
                                end;
                            else
                                local e = e[2];
                                A[e] = A[e](A[e + 1]); 
                            end;
                        elseif c <= 79 then
                            if c <= 75 then
                                if c <= 73 then
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                elseif c > 74 then
                                    local l = e[2];
                                    local c, d = {
                                        A[l](A[l + 1])
                                    }, 0;
                                    for e = l, e[4] do
                                        d = d + 1;
                                        A[e] = c[d]; 
                                    end;
                                else
                                    A[e[2]] = A[e[3]] / A[e[4]]; 
                                end;
                            elseif c <= 77 then
                                if c > 76 then
                                    local d = e[3];
                                    local l = A[d];
                                    for e = d + 1, e[4] do
                                        l = l .. A[e]; 
                                    end;
                                    A[e[2]] = l;
                                else
                                    local l = e[2];
                                    local d = A[e[3]];
                                    A[l + 1] = d;
                                    A[l] = d[e[4]]; 
                                end;
                            elseif c > 78 then
                                local c;
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](n(A, c + 1, e[3]));
                            else
                                local N;
                                local L, X;
                                local V;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]]();
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V = A[e[3]];
                                A[c + 1] = V;
                                A[c] = V[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                L, X = C(A[c](n(A, c + 1, e[3])));
                                a = X + c - 1;
                                N = 0;
                                for e = c, a do
                                    N = N + 1;
                                    A[e] = L[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                A[e[2]]();
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c <= 83 then
                            if c <= 81 then
                                if c > 80 then
                                    local o;
                                    local V, X;
                                    local N;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    N = A[e[3]];
                                    A[c + 1] = N;
                                    A[c] = N[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    V, X = C(A[c](n(A, c + 1, e[3])));
                                    a = X + c - 1;
                                    o = 0;
                                    for e = c, a do
                                        o = o + 1;
                                        A[e] = V[o]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    for e = e[2], e[3] do
                                        A[e] = nil; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    if A[e[2]] then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end;
                                else
                                    local V;
                                    local W, L;
                                    local X;
                                    local N;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    N = A[e[3]];
                                    A[c + 1] = N;
                                    A[c] = N[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    N = e[3];
                                    X = A[N];
                                    for e = N + 1, e[4] do
                                        X = X .. A[e]; 
                                    end;
                                    A[e[2]] = X;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    W, L = C(A[c](n(A, c + 1, e[3])));
                                    a = L + c - 1;
                                    V = 0;
                                    for e = c, a do
                                        V = V + 1;
                                        A[e] = W[V]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return A[e[2]](); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    do
                                        return n(A, c, a); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return; 
                                    end; 
                                end;
                            elseif c > 82 then
                                if A[e[2]] then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end;
                            else
                                local c;
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                do
                                    return A[c](n(A, c + 1, e[3])); 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                do
                                    return n(A, c, a); 
                                end;
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c <= 85 then
                            if c > 84 then
                                local B;
                                local V, N;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V, N = C(A[c](A[c + 1]));
                                a = N + c - 1;
                                B = 0;
                                for e = c, a do
                                    B = B + 1;
                                    A[e] = V[B]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                A[e[2]]();
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end;
                            else
                                local e = e[2];
                                do
                                    return A[e](n(A, e + 1, a)); 
                                end; 
                            end;
                        elseif c == 86 then
                            local d = A[e[4]];
                            if not d then
                                l = l + 1;
                            else
                                A[e[2]] = d;
                                l = e[3]; 
                            end;
                        else
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]]();
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]]();
                            l = l + 1;
                            e = d[l];
                            do
                                return; 
                            end; 
                        end;
                    elseif c <= 102 then
                        if c <= 94 then
                            if c <= 90 then
                                if c <= 88 then
                                    local e = e[2];
                                    do
                                        return A[e](n(A, e + 1, a)); 
                                    end;
                                elseif c == 89 then
                                    A[e[2]][A[e[3]]] = e[4];
                                else
                                    local e = e[2];
                                    A[e] = A[e](n(A, e + 1, a)); 
                                end;
                            elseif c <= 92 then
                                if c == 91 then
                                    local c;
                                    local a;
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[3];
                                    c = A[a];
                                    for e = a + 1, e[4] do
                                        c = c .. A[e]; 
                                    end;
                                    A[e[2]] = c;
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    if (A[e[2]] == e[4]) then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end;
                                else
                                    local e = e[2];
                                    A[e] = A[e](); 
                                end;
                            elseif c == 93 then
                                A[e[2]] = A[e[3]][A[e[4]]];
                            else
                                if (e[2] < A[e[4]]) then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end; 
                            end;
                        elseif c <= 98 then
                            if c <= 96 then
                                if c > 95 then
                                    local e = e[2];
                                    A[e](A[e + 1]);
                                else
                                    if (A[e[2]] < A[e[4]]) then
                                        l = e[3];
                                    else
                                        l = l + 1; 
                                    end; 
                                end;
                            elseif c > 97 then
                                A[e[2]] = A[e[3]] - A[e[4]];
                            else
                                local o;
                                local c;
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = c + K - 1;
                                for e = c, a do
                                    o = X[e - c];
                                    A[e] = o; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                do
                                    return A[c](n(A, c + 1, a)); 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                do
                                    return n(A, c, a); 
                                end;
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c <= 100 then
                            if c == 99 then
                                local o, a;
                                local n;
                                local c;
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = (e[3] ~= 0);
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                n = A[e[3]];
                                A[c + 1] = n;
                                A[c] = n[e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                o, a = {
                                    A[c](A[c + 1])
                                },0;
                                for e = c, e[4] do
                                    a = a + 1;
                                    A[e] = o[a]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                l = e[3];
                            else
                                local l = e[2];
                                A[l] = A[l](n(A, l + 1, e[3])); 
                            end;
                        elseif c > 101 then
                            local a;
                            local c;
                            A[e[2]] = {};
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            a = A[c];
                            for e = c + 1, e[3] do
                                M(a, A[e]); 
                            end;
                        else
                            local n = W[e[3]];
                            local a;
                            local c = {};
                            a = _({}, {
                                __index = function(l, e)
                                local e = c[e];
                                return e[1][e[2]]; 
                            end,
                                __newindex = function(A, e, l)
                                local e = c[e];
                                e[1][e[2]] = l; 
                            end
                            });
                            for a = 1, e[4] do
                                l = l + 1;
                                local e = d[l];
                                if e[1] == 9 then
                                    c[a - 1] = {
                                        A,
                                        e[3]
                                    };
                                else
                                    c[a - 1] = {
                                        o,
                                        e[3]
                                    }; 
                                end;
                                V[#V + 1] = c; 
                            end;
                            A[e[2]] = L(n, a, B); 
                        end;
                    elseif c <= 109 then
                        if c <= 105 then
                            if c <= 103 then
                                local a;
                                local c;
                                c = e[2];
                                A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                            elseif c == 104 then
                                A[e[2]][A[e[3]]] = A[e[4]];
                            else
                                local N;
                                local V, X;
                                local o;
                                local c;
                                A[e[2]][e[3]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                o = A[e[3]];
                                A[c + 1] = o;
                                A[c] = o[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V, X = C(A[c](n(A, c + 1, e[3])));
                                a = X + c - 1;
                                N = 0;
                                for e = c, a do
                                    N = N + 1;
                                    A[e] = V[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                o = A[e[3]];
                                A[c + 1] = o;
                                A[c] = o[e[4]]; 
                            end;
                        elseif c <= 107 then
                            if c > 106 then
                                local c;
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                o[e[3]] = A[e[2]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                l = e[3];
                            else
                                A[e[2]] = A[e[3]] / A[e[4]]; 
                            end;
                        elseif c == 108 then
                            local o;
                            local B, N;
                            local c;
                            c = e[2];
                            B, N = C(A[c](A[c + 1]));
                            a = N + c - 1;
                            o = 0;
                            for e = c, a do
                                o = o + 1;
                                A[e] = B[o]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                        else
                            local c;
                            local a;
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            a = e[3];
                            c = A[a];
                            for e = a + 1, e[4] do
                                c = c .. A[e]; 
                            end;
                            A[e[2]] = c;
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            a = e[3];
                            c = A[a];
                            for e = a + 1, e[4] do
                                c = c .. A[e]; 
                            end;
                            A[e[2]] = c;
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            a = e[3];
                            c = A[a];
                            for e = a + 1, e[4] do
                                c = c .. A[e]; 
                            end;
                            A[e[2]] = c;
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]]; 
                        end;
                    elseif c <= 113 then
                        if c <= 111 then
                            if c > 110 then
                                A[e[2]] = {};
                            else
                                local N;
                                local L, X;
                                local V;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V = A[e[3]];
                                A[c + 1] = V;
                                A[c] = V[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                L, X = C(A[c](n(A, c + 1, e[3])));
                                a = X + c - 1;
                                N = 0;
                                for e = c, a do
                                    N = N + 1;
                                    A[e] = L[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                A[e[2]]();
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c > 112 then
                            local l = e[2];
                            do
                                return A[l](n(A, l + 1, e[3])); 
                            end;
                        else
                            local l = e[2];
                            local c, d = {
                                A[l](n(A, l + 1, a))
                            }, 0;
                            for e = l, e[4] do
                                d = d + 1;
                                A[e] = c[d]; 
                            end; 
                        end;
                    elseif c <= 115 then
                        if c > 114 then
                            local a;
                            local c;
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            a = A[e[3]];
                            A[c + 1] = a;
                            A[c] = a[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            a = A[e[3]];
                            A[c + 1] = a;
                            A[c] = a[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                        else
                            local c;
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            if A[e[2]] then
                                l = l + 1;
                            else
                                l = e[3]; 
                            end; 
                        end;
                    elseif c > 116 then
                        local e = e[2];
                        a = e + K - 1;
                        for l = e, a do
                            local e = X[l - e];
                            A[l] = e; 
                        end;
                    else
                        A[e[2]] = A[e[3]] * e[4]; 
                    end;
                elseif c <= 176 then
                    if c <= 146 then
                        if c <= 131 then
                            if c <= 124 then
                                if c <= 120 then
                                    if c <= 118 then
                                        local n, a;
                                        local c;
                                        A[e[2]] = A[e[3]][e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](A[c + 1]);
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = (e[3] ~= 0);
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = B[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        n, a = {
                                            A[c](A[c + 1])
                                        },0;
                                        for e = c, e[4] do
                                            a = a + 1;
                                            A[e] = n[a]; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        l = e[3];
                                    elseif c > 119 then
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = {};
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = {};
                                        l = l + 1;
                                        e = d[l];
                                        for e = e[2], e[3] do
                                            A[e] = nil; 
                                        end;
                                    else
                                        local c;
                                        A[e[2]] = {};
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]][e[3]] = e[4];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c](n(A, c + 1, e[3])); 
                                    end;
                                elseif c <= 122 then
                                    if c == 121 then
                                        local a;
                                        local c;
                                        c = e[2];
                                        A[c](n(A, c + 1, e[3]));
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        a = A[e[3]];
                                        A[c + 1] = a;
                                        A[c] = a[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c] = A[c](n(A, c + 1, e[3]));
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        a = A[e[3]];
                                        A[c + 1] = a;
                                        A[c] = a[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                    else
                                        local a;
                                        local c;
                                        c = e[2];
                                        a = A[e[3]];
                                        A[c + 1] = a;
                                        A[c] = a[e[4]];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c](A[c + 1]);
                                        l = l + 1;
                                        e = d[l];
                                        for e = e[2], e[3] do
                                            A[e] = nil; 
                                        end;
                                        l = l + 1;
                                        e = d[l];
                                        o[e[3]] = A[e[2]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = o[e[3]];
                                        l = l + 1;
                                        e = d[l];
                                        A[e[2]] = e[3];
                                        l = l + 1;
                                        e = d[l];
                                        c = e[2];
                                        A[c](A[c + 1]); 
                                    end;
                                elseif c > 123 then
                                    A[e[2]]();
                                else
                                    local e = e[2];
                                    a = e + K - 1;
                                    for l = e, a do
                                        local e = X[l - e];
                                        A[l] = e; 
                                    end; 
                                end;
                            elseif c <= 127 then
                                if c <= 125 then
                                    if not A[e[2]] then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end;
                                elseif c == 126 then
                                    A[e[2]] = {};
                                else
                                    if (A[e[2]] ~= e[4]) then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end; 
                                end;
                            elseif c <= 129 then
                                if c > 128 then
                                    A[e[2]] = L(W[e[3]], nil, B);
                                else
                                    if (A[e[2]] ~= A[e[4]]) then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end; 
                                end;
                            elseif c == 130 then
                                for e = e[2], e[3] do
                                    A[e] = nil; 
                                end;
                            else
                                local a;
                                local c;
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](n(A, c + 1, e[3])); 
                            end;
                        elseif c <= 138 then
                            if c <= 134 then
                                if c <= 132 then
                                    local c, c;
                                    local N;
                                    local V, L;
                                    local X;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c]();
                                    l = l + 1;
                                    e = d[l];
                                    o[e[3]] = A[e[2]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = {};
                                    l = l + 1;
                                    e = d[l];
                                    o[e[3]] = A[e[2]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    X = A[e[3]];
                                    A[c + 1] = X;
                                    A[c] = X[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    V, L = C(A[c](A[c + 1]));
                                    a = L + c - 1;
                                    N = 0;
                                    for e = c, a do
                                        N = N + 1;
                                        A[e] = V[N]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    V, N = {
                                        A[c](n(A, c + 1, a))
                                    },0;
                                    for e = c, e[4] do
                                        N = N + 1;
                                        A[e] = V[N]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    l = e[3];
                                elseif c > 133 then
                                    local e = e[2];
                                    do
                                        return n(A, e, a); 
                                    end;
                                else
                                    A[e[2]] = (not A[e[3]]); 
                                end;
                            elseif c <= 136 then
                                if c > 135 then
                                    local N;
                                    local C;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    C = A[e[3]];
                                    A[c + 1] = C;
                                    A[c] = C[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    C = e[3];
                                    N = A[C];
                                    for e = C + 1, e[4] do
                                        N = N .. A[e]; 
                                    end;
                                    A[e[2]] = N;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    do
                                        return A[c](n(A, c + 1, e[3])); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    do
                                        return n(A, c, a); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return; 
                                    end;
                                else
                                    A[e[2]] = (e[3] ~= 0); 
                                end;
                            elseif c == 137 then
                                A[e[2]] = A[e[3]] + e[4];
                            else
                                local l = e[2];
                                A[l](n(A, l + 1, e[3])); 
                            end;
                        elseif c <= 142 then
                            if c <= 140 then
                                if c == 139 then
                                    local N;
                                    local X, V;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    X, V = C(A[c](A[c + 1]));
                                    a = V + c - 1;
                                    N = 0;
                                    for e = c, a do
                                        N = N + 1;
                                        A[e] = X[N]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    X, V = C(A[c](n(A, c + 1, a)));
                                    a = V + c - 1;
                                    N = 0;
                                    for e = c, a do
                                        N = N + 1;
                                        A[e] = X[N]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    l = e[3];
                                else
                                    local a;
                                    local c;
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = A[e[3]];
                                    A[c + 1] = a;
                                    A[c] = a[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, e[3]));
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = A[e[3]];
                                    A[c + 1] = a;
                                    A[c] = a[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return; 
                                    end; 
                                end;
                            elseif c == 141 then
                                local e = e[2];
                                local d, l = C(A[e](A[e + 1]));
                                a = l + e - 1;
                                local l = 0;
                                for e = e, a do
                                    l = l + 1;
                                    A[e] = d[l]; 
                                end;
                            else
                                local a;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = (e[3] ~= 0);
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c <= 144 then
                            if c == 143 then
                                if (A[e[2]] == e[4]) then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end;
                            else
                                local o;
                                local B;
                                local a;
                                local C;
                                local N;
                                local c;
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                A[e[2]][A[e[3]]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                N = {};
                                for e = 1, #V do
                                    C = V[e];
                                    for e = 0, #C do
                                        a = C[e];
                                        B = a[1];
                                        o = a[2];
                                        if B == A and o >= c then
                                            N[o] = B[o];
                                            a[1] = N; 
                                        end; 
                                    end; 
                                end; 
                            end;
                        elseif c > 145 then
                            local X;
                            local _;
                            local L;
                            local M;
                            local K;
                            local W;
                            local U, O;
                            local N;
                            local c;
                            c = e[2];
                            A[c](A[c + 1]);
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            U, O = C(A[c](n(A, c + 1, e[3])));
                            a = O + c - 1;
                            W = 0;
                            for e = c, a do
                                W = W + 1;
                                A[e] = U[W]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = {};
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            K = {};
                            for e = 1, #V do
                                M = V[e];
                                for e = 0, #M do
                                    L = M[e];
                                    _ = L[1];
                                    X = L[2];
                                    if _ == A and X >= c then
                                        K[X] = _[X];
                                        L[1] = K; 
                                    end; 
                                end; 
                            end;
                        else
                            local d = e[2];
                            local a = e[4];
                            local c = d + 2;
                            local d = {
                                A[d](A[d + 1], A[c])
                            };
                            for e = 1, a do
                                A[c + e] = d[e]; 
                            end;
                            local d = d[1];
                            if d then
                                A[c] = d;
                                l = e[3];
                            else
                                l = l + 1; 
                            end; 
                        end;
                    elseif c <= 161 then
                        if c <= 153 then
                            if c <= 149 then
                                if c <= 147 then
                                    local c;
                                    local n;
                                    local a;
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    a = e[2];
                                    A[a] = A[a](A[a + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    n = e[3];
                                    c = A[n];
                                    for e = n + 1, e[4] do
                                        c = c .. A[e]; 
                                    end;
                                    A[e[2]] = c;
                                    l = l + 1;
                                    e = d[l];
                                    if A[e[2]] then
                                        l = l + 1;
                                    else
                                        l = e[3]; 
                                    end;
                                elseif c == 148 then
                                    local e = e[2];
                                    A[e] = A[e]();
                                else
                                    local a;
                                    local c;
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = A[e[3]];
                                    A[c + 1] = a;
                                    A[c] = a[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = A[e[3]];
                                    A[c + 1] = a;
                                    A[c] = a[e[4]]; 
                                end;
                            elseif c <= 151 then
                                if c > 150 then
                                    local X;
                                    local o;
                                    local V, N;
                                    local c;
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    V, N = C(A[c](n(A, c + 1, e[3])));
                                    a = N + c - 1;
                                    o = 0;
                                    for e = c, a do
                                        o = o + 1;
                                        A[e] = V[o]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    X = A[e[3]];
                                    A[c + 1] = X;
                                    A[c] = X[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    V, N = C(A[c](n(A, c + 1, e[3])));
                                    a = N + c - 1;
                                    o = 0;
                                    for e = c, a do
                                        o = o + 1;
                                        A[e] = V[o]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = {};
                                else
                                    local n, a;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](A[c + 1]);
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = {};
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    n, a = {
                                        A[c](A[c + 1])
                                    },0;
                                    for e = c, e[4] do
                                        a = a + 1;
                                        A[e] = n[a]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    l = e[3]; 
                                end;
                            elseif c > 152 then
                                local c;
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end;
                            else
                                local n;
                                local a;
                                local c;
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                a = e[3];
                                n = A[a];
                                for e = a + 1, e[4] do
                                    n = n .. A[e]; 
                                end;
                                A[e[2]] = n;
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][A[e[4]]];
                                l = l + 1;
                                e = d[l];
                                if A[e[2]] then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end; 
                            end;
                        elseif c <= 157 then
                            if c <= 155 then
                                if c == 154 then
                                    local N;
                                    local X, L;
                                    local V;
                                    local c;
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    V = A[e[3]];
                                    A[c + 1] = V;
                                    A[c] = V[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    X, L = C(A[c](n(A, c + 1, e[3])));
                                    a = L + c - 1;
                                    N = 0;
                                    for e = c, a do
                                        N = N + 1;
                                        A[e] = X[N]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]]();
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return; 
                                    end;
                                else
                                    local N;
                                    local C;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    C = A[e[3]];
                                    A[c + 1] = C;
                                    A[c] = C[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    C = e[3];
                                    N = A[C];
                                    for e = C + 1, e[4] do
                                        N = N .. A[e]; 
                                    end;
                                    A[e[2]] = N;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    do
                                        return A[c](n(A, c + 1, e[3])); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    do
                                        return n(A, c, a); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return; 
                                    end; 
                                end;
                            elseif c > 156 then
                                local l = e[2];
                                local d, e = C(A[l](n(A, l + 1, e[3])));
                                a = e + l - 1;
                                local e = 0;
                                for l = l, a do
                                    e = e + 1;
                                    A[l] = d[e]; 
                                end;
                            else
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]]; 
                            end;
                        elseif c <= 159 then
                            if c == 158 then
                                local o;
                                local B, N;
                                local c;
                                c = e[2];
                                B, N = C(A[c](A[c + 1]));
                                a = N + c - 1;
                                o = 0;
                                for e = c, a do
                                    o = o + 1;
                                    A[e] = B[o]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                            else
                                if (A[e[2]] ~= e[4]) then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end; 
                            end;
                        elseif c > 160 then
                            o[e[3]] = A[e[2]];
                        else
                            local N;
                            local X, L;
                            local V;
                            local c;
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            V = A[e[3]];
                            A[c + 1] = V;
                            A[c] = V[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            X, L = C(A[c](n(A, c + 1, e[3])));
                            a = L + c - 1;
                            N = 0;
                            for e = c, a do
                                N = N + 1;
                                A[e] = X[N]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            A[e[2]]();
                            l = l + 1;
                            e = d[l];
                            do
                                return; 
                            end; 
                        end;
                    elseif c <= 168 then
                        if c <= 164 then
                            if c <= 162 then
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                            elseif c > 163 then
                                local a;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                            else
                                A[e[2]][e[3]] = e[4]; 
                            end;
                        elseif c <= 166 then
                            if c == 165 then
                                local e = e[2];
                                local d, l = C(A[e](n(A, e + 1, a)));
                                a = l + e - 1;
                                local l = 0;
                                for e = e, a do
                                    l = l + 1;
                                    A[e] = d[l]; 
                                end;
                            else
                                local N;
                                local V, X;
                                local o;
                                local c;
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                o = A[e[3]];
                                A[c + 1] = o;
                                A[c] = o[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V, X = C(A[c](n(A, c + 1, e[3])));
                                a = X + c - 1;
                                N = 0;
                                for e = c, a do
                                    N = N + 1;
                                    A[e] = V[N]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, a));
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                o = A[e[3]];
                                A[c + 1] = o;
                                A[c] = o[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4]; 
                            end;
                        elseif c > 167 then
                            A[e[2]] = #A[e[3]];
                        else
                            local N;
                            local V, X;
                            local o;
                            local c;
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            o = A[e[3]];
                            A[c + 1] = o;
                            A[c] = o[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            V, X = C(A[c](n(A, c + 1, e[3])));
                            a = X + c - 1;
                            N = 0;
                            for e = c, a do
                                N = N + 1;
                                A[e] = V[N]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            o = A[e[3]];
                            A[c + 1] = o;
                            A[c] = o[e[4]]; 
                        end;
                    elseif c <= 172 then
                        if c <= 170 then
                            if c > 169 then
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = A[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                            else
                                local a;
                                local c;
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c]();
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3]; 
                            end;
                        elseif c > 171 then
                            local d = e[3];
                            local l = A[d];
                            for e = d + 1, e[4] do
                                l = l .. A[e]; 
                            end;
                            A[e[2]] = l;
                        else
                            local V;
                            local X, L;
                            local N;
                            local c;
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            X, L = C(A[c](n(A, c + 1, e[3])));
                            a = L + c - 1;
                            V = 0;
                            for e = c, a do
                                V = V + 1;
                                A[e] = X[V]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](A[c + 1]);
                            l = l + 1;
                            e = d[l];
                            do
                                return; 
                            end; 
                        end;
                    elseif c <= 174 then
                        if c > 173 then
                            A[e[2]]();
                        else
                            do
                                return A[e[2]](); 
                            end; 
                        end;
                    elseif c == 175 then
                        local l = e[2];
                        local d = A[l];
                        for e = l + 1, e[3] do
                            M(d, A[e]); 
                        end;
                    else
                        do
                            return A[e[2]]; 
                        end; 
                    end;
                elseif c <= 206 then
                    if c <= 191 then
                        if c <= 183 then
                            if c <= 179 then
                                if c <= 177 then
                                    A[e[2]] = o[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = {};
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                elseif c > 178 then
                                    local o;
                                    local c;
                                    A[e[2]] = A[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = c + K - 1;
                                    for e = c, a do
                                        o = X[e - c];
                                        A[e] = o; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    do
                                        return A[c](n(A, c + 1, a)); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    do
                                        return n(A, c, a); 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    do
                                        return; 
                                    end;
                                else
                                    local a;
                                    local c;
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = A[e[3]][e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    a = A[e[3]];
                                    A[c + 1] = a;
                                    A[c] = a[e[4]]; 
                                end;
                            elseif c <= 181 then
                                if c == 180 then
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]][e[3]] = e[4];
                                else
                                    o[e[3]] = A[e[2]]; 
                                end;
                            elseif c == 182 then
                                local l = e[2];
                                A[l] = A[l](n(A, l + 1, e[3]));
                            else
                                local c;
                                A[e[2]] = (e[3] ~= 0);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                if (A[e[2]] == e[4]) then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end; 
                            end;
                        elseif c <= 187 then
                            if c <= 185 then
                                if c > 184 then
                                    A[e[2]] = B[e[3]];
                                else
                                    local o;
                                    local X, V;
                                    local N;
                                    local c;
                                    A[e[2]] = B[e[3]];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    N = A[e[3]];
                                    A[c + 1] = N;
                                    A[c] = N[e[4]];
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]] = e[3];
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    X, V = C(A[c](n(A, c + 1, e[3])));
                                    a = V + c - 1;
                                    o = 0;
                                    for e = c, a do
                                        o = o + 1;
                                        A[e] = X[o]; 
                                    end;
                                    l = l + 1;
                                    e = d[l];
                                    c = e[2];
                                    A[c] = A[c](n(A, c + 1, a));
                                    l = l + 1;
                                    e = d[l];
                                    A[e[2]](); 
                                end;
                            elseif c > 186 then
                                local a;
                                local c;
                                o[e[3]] = A[e[2]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                do
                                    return A[e[2]]; 
                                end;
                            else
                                local a;
                                local n;
                                local c;
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                n = e[3];
                                a = A[n];
                                for e = n + 1, e[4] do
                                    a = a .. A[e]; 
                                end;
                                A[e[2]] = a;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c <= 189 then
                            if c == 188 then
                                local a;
                                local c;
                                local n;
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                n = e[3];
                                c = A[n];
                                for e = n + 1, e[4] do
                                    c = c .. A[e]; 
                                end;
                                A[e[2]] = c;
                                l = l + 1;
                                e = d[l];
                                a = e[2];
                                A[a] = A[a](A[a + 1]);
                                l = l + 1;
                                e = d[l];
                                if A[e[2]] then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end;
                            else
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4];
                                l = l + 1;
                                e = d[l];
                                A[e[2]][e[3]] = e[4]; 
                            end;
                        elseif c > 190 then
                            local e = e[2];
                            A[e](n(A, e + 1, a));
                        else
                            A[e[2]] = B[e[3]]; 
                        end;
                    elseif c <= 198 then
                        if c <= 194 then
                            if c <= 192 then
                                local e = e[2];
                                do
                                    return n(A, e, a); 
                                end;
                            elseif c > 193 then
                                local C;
                                local a;
                                local c;
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                for e = e[2], e[3] do
                                    A[e] = nil; 
                                end;
                                l = l + 1;
                                e = d[l];
                                o[e[3]] = A[e[2]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = o[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                a = e[3];
                                C = A[a];
                                for e = a + 1, e[4] do
                                    C = C .. A[e]; 
                                end;
                                A[e[2]] = C;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                            else
                                do
                                    return A[e[2]](); 
                                end; 
                            end;
                        elseif c <= 196 then
                            if c > 195 then
                                A[e[2]] = A[e[3]] + e[4];
                            else
                                if not A[e[2]] then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end; 
                            end;
                        elseif c > 197 then
                            A[e[2]] = A[e[3]] - A[e[4]];
                        else
                            local c;
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](A[c + 1]);
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]]; 
                        end;
                    elseif c <= 202 then
                        if c <= 200 then
                            if c > 199 then
                                A[e[2]] = A[e[3]][e[4]];
                            else
                                A[e[2]] = (e[3] ~= 0);
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = {};
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = B[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]][e[4]]; 
                            end;
                        elseif c == 201 then
                            local o;
                            local N, V;
                            local c;
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N, V = C(A[c](n(A, c + 1, e[3])));
                            a = V + c - 1;
                            o = 0;
                            for e = c, a do
                                o = o + 1;
                                A[e] = N[o]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, a));
                        else
                            local c = e[2];
                            local a = e[4];
                            local d = c + 2;
                            local c = {
                                A[c](A[c + 1], A[d])
                            };
                            for e = 1, a do
                                A[d + e] = c[e]; 
                            end;
                            local c = c[1];
                            if c then
                                A[d] = c;
                                l = e[3];
                            else
                                l = l + 1; 
                            end; 
                        end;
                    elseif c <= 204 then
                        if c == 203 then
                            local c;
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](A[c + 1]);
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                        else
                            local V;
                            local L, X;
                            local N;
                            local c;
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            L, X = C(A[c](n(A, c + 1, e[3])));
                            a = X + c - 1;
                            V = 0;
                            for e = c, a do
                                V = V + 1;
                                A[e] = L[V]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            do
                                return A[c](n(A, c + 1, a)); 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            do
                                return n(A, c, a); 
                            end;
                            l = l + 1;
                            e = d[l];
                            do
                                return; 
                            end; 
                        end;
                    elseif c == 205 then
                        A[e[2]] = A[e[3]] * e[4];
                    else
                        local a;
                        local c;
                        A[e[2]] = A[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = A[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = A[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = A[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = A[e[3]];
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        a = A[c];
                        for e = c + 1, e[3] do
                            M(a, A[e]); 
                        end; 
                    end;
                elseif c <= 221 then
                    if c <= 213 then
                        if c <= 209 then
                            if c <= 207 then
                                local c;
                                local a;
                                local n;
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                n = e[3];
                                a = A[n];
                                for e = n + 1, e[4] do
                                    a = a .. A[e]; 
                                end;
                                A[e[2]] = a;
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](A[c + 1]);
                                l = l + 1;
                                e = d[l];
                                if not A[e[2]] then
                                    l = l + 1;
                                else
                                    l = e[3]; 
                                end;
                            elseif c > 208 then
                                l = e[3];
                            else
                                local B;
                                local a;
                                local c;
                                c = e[2];
                                a = A[e[3]];
                                A[c + 1] = a;
                                A[c] = a[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c] = A[c](n(A, c + 1, e[3]));
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = e[3];
                                l = l + 1;
                                e = d[l];
                                a = e[3];
                                B = A[a];
                                for e = a + 1, e[4] do
                                    B = B .. A[e]; 
                                end;
                                A[e[2]] = B;
                                l = l + 1;
                                e = d[l];
                                o[e[3]] = A[e[2]];
                                l = l + 1;
                                e = d[l];
                                do
                                    return; 
                                end; 
                            end;
                        elseif c <= 211 then
                            if c == 210 then
                                l = e[3];
                            else
                                A[e[2]] = o[e[3]]; 
                            end;
                        elseif c == 212 then
                            local a = e[2];
                            local c = {};
                            for e = 1, #V do
                                local e = V[e];
                                for l = 0, #e do
                                    local e = e[l];
                                    local d = e[1];
                                    local l = e[2];
                                    if d == A and l >= a then
                                        c[l] = d[l];
                                        e[1] = c; 
                                    end; 
                                end; 
                            end;
                        else
                            local l = e[2];
                            local d, e = C(A[l](n(A, l + 1, e[3])));
                            a = e + l - 1;
                            local e = 0;
                            for l = l, a do
                                e = e + 1;
                                A[l] = d[e]; 
                            end; 
                        end;
                    elseif c <= 217 then
                        if c <= 215 then
                            if c > 214 then
                                A[e[2]] = o[e[3]];
                            else
                                local o;
                                local V, N;
                                local B;
                                local c;
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                B = A[e[3]];
                                A[c + 1] = B;
                                A[c] = B[e[4]];
                                l = l + 1;
                                e = d[l];
                                A[e[2]] = A[e[3]];
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                V, N = C(A[c](n(A, c + 1, e[3])));
                                a = N + c - 1;
                                o = 0;
                                for e = c, a do
                                    o = o + 1;
                                    A[e] = V[o]; 
                                end;
                                l = l + 1;
                                e = d[l];
                                c = e[2];
                                A[c](n(A, c + 1, a)); 
                            end;
                        elseif c > 216 then
                            local o;
                            local V, X;
                            local N;
                            local c;
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            N = A[e[3]];
                            A[c + 1] = N;
                            A[c] = N[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            V, X = C(A[c](n(A, c + 1, e[3])));
                            a = X + c - 1;
                            o = 0;
                            for e = c, a do
                                o = o + 1;
                                A[e] = V[o]; 
                            end;
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, a));
                            l = l + 1;
                            e = d[l];
                            A[e[2]]();
                        else
                            local c;
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]]();
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3])); 
                        end;
                    elseif c <= 219 then
                        if c > 218 then
                            local c;
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c]();
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c]();
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]] - A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = {};
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                        else
                            o[e[3]] = A[e[2]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]]();
                            l = l + 1;
                            e = d[l];
                            l = e[3]; 
                        end;
                    elseif c == 220 then
                        if (A[e[2]] == e[4]) then
                            l = l + 1;
                        else
                            l = e[3]; 
                        end;
                    else
                        if (A[e[2]] < A[e[4]]) then
                            l = e[3];
                        else
                            l = l + 1; 
                        end; 
                    end;
                elseif c <= 228 then
                    if c <= 224 then
                        if c <= 222 then
                            local c;
                            local a;
                            a = e[3];
                            c = A[a];
                            for e = a + 1, e[4] do
                                c = c .. A[e]; 
                            end;
                            A[e[2]] = c;
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            a = e[3];
                            c = A[a];
                            for e = a + 1, e[4] do
                                c = c .. A[e]; 
                            end;
                            A[e[2]] = c;
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            a = e[3];
                            c = A[a];
                            for e = a + 1, e[4] do
                                c = c .. A[e]; 
                            end;
                            A[e[2]] = c;
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                        elseif c > 223 then
                            local c;
                            local n;
                            local a;
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][A[e[4]]];
                            l = l + 1;
                            e = d[l];
                            a = e[2];
                            A[a] = A[a](A[a + 1]);
                            l = l + 1;
                            e = d[l];
                            n = e[3];
                            c = A[n];
                            for e = n + 1, e[4] do
                                c = c .. A[e]; 
                            end;
                            A[e[2]] = c;
                        else
                            local a;
                            local c;
                            c = e[2];
                            a = A[e[3]];
                            A[c + 1] = a;
                            A[c] = a[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            if not A[e[2]] then
                                l = l + 1;
                            else
                                l = e[3]; 
                            end; 
                        end;
                    elseif c <= 226 then
                        if c == 225 then
                            local a;
                            local c;
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            a = A[e[3]];
                            A[c + 1] = a;
                            A[c] = a[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c] = A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            a = A[e[3]];
                            A[c + 1] = a;
                            A[c] = a[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                        else
                            A[e[2]][e[3]] = A[e[4]]; 
                        end;
                    elseif c == 227 then
                        local a;
                        local n;
                        local c;
                        A[e[2]] = e[3];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = B[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = A[e[3]];
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        A[c] = A[c](A[c + 1]);
                        l = l + 1;
                        e = d[l];
                        n = e[3];
                        a = A[n];
                        for e = n + 1, e[4] do
                            a = a .. A[e]; 
                        end;
                        A[e[2]] = a;
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        A[c](A[c + 1]);
                    else
                        local V;
                        local W, L;
                        local X;
                        local N;
                        local c;
                        A[e[2]] = B[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = B[e[3]];
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        N = A[e[3]];
                        A[c + 1] = N;
                        A[c] = N[e[4]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = o[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = o[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = e[3];
                        l = l + 1;
                        e = d[l];
                        N = e[3];
                        X = A[N];
                        for e = N + 1, e[4] do
                            X = X .. A[e]; 
                        end;
                        A[e[2]] = X;
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        W, L = C(A[c](n(A, c + 1, e[3])));
                        a = L + c - 1;
                        V = 0;
                        for e = c, a do
                            V = V + 1;
                            A[e] = W[V]; 
                        end;
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        do
                            return A[c](n(A, c + 1, a)); 
                        end;
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        do
                            return n(A, c, a); 
                        end;
                        l = l + 1;
                        e = d[l];
                        do
                            return; 
                        end; 
                    end;
                elseif c <= 232 then
                    if c <= 230 then
                        if c == 229 then
                            local a;
                            local c;
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            a = A[e[3]];
                            A[c + 1] = a;
                            A[c] = a[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = e[3];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = {};
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = e[4];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = o[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]][e[3]] = A[e[4]];
                            l = l + 1;
                            e = d[l];
                            c = e[2];
                            A[c](n(A, c + 1, e[3]));
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = B[e[3]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]][e[4]];
                            l = l + 1;
                            e = d[l];
                            A[e[2]] = A[e[3]];
                        else
                            local d = e[2];
                            local c, l = {
                                A[d](A[d + 1])
                            }, 0;
                            for e = d, e[4] do
                                l = l + 1;
                                A[e] = c[l]; 
                            end; 
                        end;
                    elseif c == 231 then
                        local a;
                        local c;
                        c = e[2];
                        a = A[e[3]];
                        A[c + 1] = a;
                        A[c] = a[e[4]];
                        l = l + 1;
                        e = d[l];
                        c = e[2];
                        A[c](A[c + 1]);
                        l = l + 1;
                        e = d[l];
                        for e = e[2], e[3] do
                            A[e] = nil; 
                        end;
                        l = l + 1;
                        e = d[l];
                        o[e[3]] = A[e[2]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = o[e[3]];
                        l = l + 1;
                        e = d[l];
                        if A[e[2]] then
                            l = l + 1;
                        else
                            l = e[3]; 
                        end;
                    else
                        A[e[2]] = A[e[3]][e[4]]; 
                    end;
                elseif c <= 234 then
                    if c > 233 then
                        A[e[2]][A[e[3]]] = e[4];
                    else
                        local c;
                        c = e[2];
                        A[c] = A[c](A[c + 1]);
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = B[e[3]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = A[e[3]][e[4]];
                        l = l + 1;
                        e = d[l];
                        A[e[2]] = A[e[3]][e[4]];
                        l = l + 1;
                        e = d[l];
                        if (A[e[2]] ~= A[e[4]]) then
                            l = l + 1;
                        else
                            l = e[3]; 
                        end; 
                    end;
                elseif c > 235 then
                    do
                        return; 
                    end;
                else
                    local c;
                    A[e[2]] = o[e[3]];
                    l = l + 1;
                    e = d[l];
                    A[e[2]]();
                    l = l + 1;
                    e = d[l];
                    A[e[2]] = B[e[3]];
                    l = l + 1;
                    e = d[l];
                    A[e[2]] = A[e[3]][e[4]];
                    l = l + 1;
                    e = d[l];
                    A[e[2]] = e[3];
                    l = l + 1;
                    e = d[l];
                    c = e[2];
                    A[c] = A[c](A[c + 1]);
                    l = l + 1;
                    e = d[l];
                    A[e[2]] = B[e[3]];
                    l = l + 1;
                    e = d[l];
                    A[e[2]] = A[e[3]][e[4]];
                    l = l + 1;
                    e = d[l];
                    A[e[2]] = e[3];
                    l = l + 1;
                    e = d[l];
                    c = e[2];
                    A[c] = A[c](A[c + 1]);
                    l = l + 1;
                    e = d[l];
                    A[e[2]] = A[e[3]][e[4]];
                    l = l + 1;
                    e = d[l];
                    if not A[e[2]] then
                        l = l + 1;
                    else
                        l = e[3]; 
                    end; 
                end;
                l = l + 1; 
            end; 
        end; 
    end;
    local old; old = hookfunction(L, newcclosure(function(...)
        local result = old(...)
        local oldd; oldd = hookfunction(result, function(...)
            DumpTable(...) -- printing here?
            return oldd(...)
        end)
        return result
    end))
    return L(O(), {}, Y)(...); 
end))(...);
