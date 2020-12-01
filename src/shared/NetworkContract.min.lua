--[[
	NetworkContract v1.0 [2020-12-01 09:05]

   Facilitates Client Server communication through Events. Has Encode, Decode, Diff, Patch and Message Knowledge

	This is a minified version of NetworkContract, to see the full source code visit
	https://github.com/nidorx/roblox-network-contract

	Discussions about this script are at https://devforum.roblox.com/t/@TODO_ID_FORUM

	This code was minified using https://goonlinetools.com/lua-minifier/

	------------------------------------------------------------------------------

	MIT License

   Copyright (c) 2020 Alex Rodin

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
]]
local a=game:GetService('RunService')local b=bit32.band;local c=bit32.bor;local d=bit32.lshift;local e={}local f=0x0;for g=0,31 do table.insert(e,d(1,g))end;local h=0.00001;local function i(j,k)if j==k then return true end;return math.abs(j-k)<h end;local function l(m,n)local o=f;local p={true,o}for q,r in ipairs(n)do local s=m[r]if s~=nil then o=c(o,e[q])table.insert(p,s)end end;if o==f then return nil end;p[2]=o;return p end;local function t(m,n,u)if not m then return{}end;local p={}local v=table.getn(m)local o=m[2]local w=1;for g=3,v do for x=w,u do w=w+1;if b(o,e[x])~=f then p[n[x]]=m[g]break end end end;return p end;local function y(z,A,n)local B=f;local C=f;local p={false,C,B}for q,r in ipairs(n)do local D=z[r]local E=A[r]if D==nil then if E~=nil then B=c(B,e[q])table.insert(p,E)end elseif E==nil then C=c(C,e[q])else local F=typeof(D)local G=typeof(E)local H=false;if F=='number'and G=='number'and not i(D,E)then H=true elseif D~=E then H=true end;if H then B=c(B,e[q])table.insert(p,E)end end end;if C==f and B==f then return nil end;p[2]=C;p[3]=B;return p end;local function I(z,J,n,K,u)if not J then J={false,f,f}end;if not z then z={}end;local p={}local C=J[2]local B=J[3]local L={}local v=table.getn(J)local w=1;if B~=f then for g=4,v do for x=w,u do w=w+1;local M=e[x]if b(C,M)~=f then L[x]=true elseif b(B,M)~=f then L[x]=true;p[n[x]]=J[g]break end end end end;if C>=d(1,w-1)then for x=w,u do w=w+1;if b(C,e[x])~=f then L[x]=true end end end;for r,s in pairs(z)do local q=K[r]if q~=nil and s~=nil and not L[q]then p[r]=s end end;return p end;local function N(O,P,Q,R)local K={}local n={}for q,r in ipairs(P)do K[r]=q;table.insert(n,r)end;local u=table.getn(n)local S='NCRCT_'..O;local T;local U={Encode=function(m)return l(m,n)end,Decode=function(m)return t(m,n,u)end,Diff=function(z,A)return y(z,A,n)end,Patch=function(z,J)return I(z,J,n,K,u)end}if a:IsServer()then if game.ReplicatedStorage:FindFirstChild(S)then error('There is already an event with the given ID ('..S..')')end;T=Instance.new('RemoteEvent')T.Parent=game.ReplicatedStorage;T.Name=S;T.OnServerEvent:Connect(function(V,W)local m=W[1]local X=W[2]if m==true then if X~=nil and R~=nil then R(X,V,U)end else if X~=nil then T:FireClient(V,{true,X})end;if Q~=nil then Q(m,X,m~=nil and m[1]==false or false,V,U)end end end)U.Send=function(m,X,V)T:FireClient(V,{m,X})end else T=game.ReplicatedStorage:WaitForChild(S)T.OnClientEvent:Connect(function(W)local m=W[1]local X=W[2]if m==true then if X~=nil and R~=nil then R(X,nil,U)end else if X~=nil then T:FireServer({true,X})end;if Q~=nil then Q(m,X,m~=nil and m[1]==false or false,nil,U)end end end)U.Send=function(m,X)T:FireServer({m,X})end end;return U end;return N