--[[
	NetworkContract v1.0 [2020-12-01 15:40]

   Facilitates Client Server communication through Events. Has Encode, Decode, Diff, Patch and Message Knowledge

	This is a minified version of NetworkContract, to see the full source code visit
	https://github.com/nidorx/roblox-network-contract

	Discussions about this script are at https://devforum.roblox.com/t/900276

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
local a=game:GetService('RunService')local b=bit32.band;local c=bit32.bor;local d=bit32.lshift;local e={}local f=0x0;for g=0,31 do table.insert(e,d(1,g))end;local h=0.00001;local function i(j,k)if j==k then return true end;return math.abs(j-k)<h end;local function l(m,n)if m==n then return true end;if not m.Position:FuzzyEq(n.Position)then return false end;if not m.LookVector:FuzzyEq(n.LookVector)then return false end;if not m.RightVector:FuzzyEq(n.RightVector)then return false end;if not m.UpVector:FuzzyEq(n.UpVector)then return false end;return true end;local function o(p,q)local r=f;local s={true,r}for t,u in ipairs(q)do local v=p[u]if v~=nil then r=c(r,e[t])table.insert(s,v)end end;if r==f then return nil end;s[2]=r;return s end;local function w(p,q,x)if not p then return{}end;local s={}local y=table.getn(p)local r=p[2]local z=1;for g=3,y do for A=z,x do z=z+1;if b(r,e[A])~=f then s[q[A]]=p[g]break end end end;return s end;local function B(C,D,q)local E=f;local F=f;local s={false,F,E}for t,u in ipairs(q)do local G=C[u]local H=D[u]if G==nil then if H~=nil then E=c(E,e[t])table.insert(s,H)end elseif H==nil then F=c(F,e[t])else local I=typeof(G)local J=typeof(H)local K=false;if I==J then if I=='number'and not i(G,H)then K=true elseif I=='Vector3'and not G:FuzzyEq(H)then K=true elseif I=='CFrame'and not l(G,H)then K=true elseif G~=H then K=true end elseif G~=H then K=true end;if K then E=c(E,e[t])table.insert(s,H)end end end;if F==f and E==f then return nil end;s[2]=F;s[3]=E;return s end;local function L(C,M,q,N,x)if not M then M={false,f,f}end;if not C then C={}end;local s={}local F=M[2]local E=M[3]local O={}local y=table.getn(M)local z=1;if E~=f then for g=4,y do for A=z,x do z=z+1;local P=e[A]if b(F,P)~=f then O[A]=true elseif b(E,P)~=f then O[A]=true;s[q[A]]=M[g]break end end end end;if F>=d(1,z-1)then for A=z,x do z=z+1;if b(F,e[A])~=f then O[A]=true end end end;for u,v in pairs(C)do local t=N[u]if t~=nil and v~=nil and not O[t]then s[u]=v end end;return s end;local function Q(R,S,T,U,V)local N={}local q={}for t,u in ipairs(S)do N[u]=t;table.insert(q,u)end;local x=table.getn(q)local W='NCRCT_'..R;local X;local Y={Encode=function(p)return o(p,q)end,Decode=function(p)return w(p,q,x)end,Diff=function(C,D)return B(C,D,q)end,Patch=function(C,M)return L(C,M,q,N,x)end}if a:IsServer()then if game.ReplicatedStorage:FindFirstChild(W)then error('There is already an event with the given ID ('..W..')')end;X=Instance.new('RemoteEvent')X.Parent=game.ReplicatedStorage;X.Name=W;X.OnServerEvent:Connect(function(Z,_)local p=_[1]local a0=_[2]if p==true then if a0~=nil and U~=nil then U(a0,Z,Y)end else if V~=false and a0~=nil then X:FireClient(Z,{true,a0})end;if T~=nil then T(p,a0,p~=nil and p[1]==false or false,Z,Y)end end end)Y.Send=function(p,a0,Z)X:FireClient(Z,{p,a0})end;Y.Acknowledge=function(a0,Z)X:FireClient(Z,{true,a0})end else X=game.ReplicatedStorage:WaitForChild(W)X.OnClientEvent:Connect(function(_)local p=_[1]local a0=_[2]if p==true then if a0~=nil and U~=nil then U(a0,nil,Y)end else if V~=false and a0~=nil then X:FireServer({true,a0})end;if T~=nil then T(p,a0,p~=nil and p[1]==false or false,nil,Y)end end end)Y.Send=function(p,a0)X:FireServer({p,a0})end;Y.Acknowledge=function(a0)X:FireServer({true,a0})end end;return Y end;return Q