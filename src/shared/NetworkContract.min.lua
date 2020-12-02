--[[
	NetworkContract v1.1 [2020-12-02 14:30]

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
local a=game:GetService('RunService')local b=bit32.band;local c=bit32.bor;local d=bit32.lshift;local e={}local f=0x0;for g=0,31 do table.insert(e,d(1,g))end;local h=0.2;local i=1-h;local j={}local k=0;local function l()end;local m=0.00001;local function n(o,p)if o==p then return true end;return math.abs(o-p)<m end;local function q(r,s)if r==s then return true end;if not r.Position:FuzzyEq(s.Position)then return false end;if not r.LookVector:FuzzyEq(s.LookVector)then return false end;if not r.RightVector:FuzzyEq(s.RightVector)then return false end;if not r.UpVector:FuzzyEq(s.UpVector)then return false end;return true end;local function t(u,v)local w=f;local x={true,w}for y,z in ipairs(v)do local A=u[z]if A~=nil then w=c(w,e[y])table.insert(x,A)end end;x[2]=w;return x end;local function B(u,v,C)if not u then return{}end;local x={}local D=table.getn(u)local w=u[2]local E=1;for g=3,D do for F=E,C do E=E+1;if b(w,e[F])~=f then x[v[F]]=u[g]break end end end;return x end;local function G(H,I,v)local J=f;local K=f;local x={K,J}for y,z in ipairs(v)do local L=H[z]local M=I[z]if L==nil then if M~=nil then J=c(J,e[y])table.insert(x,M)end elseif M==nil then K=c(K,e[y])else local N=typeof(L)local O=typeof(M)local P=false;if N==O then if N=='number'and not n(L,M)then P=true elseif N=='Vector3'and not L:FuzzyEq(M)then P=true elseif N=='CFrame'and not q(L,M)then P=true elseif L~=M then P=true end elseif L~=M then P=true end;if P then J=c(J,e[y])table.insert(x,M)end end end;x[1]=K;x[2]=J;return x end;local function Q(H,R,v,S,C)if not R then R={f,f}end;if not H then H={}end;local x={}local K=R[1]local J=R[2]local T={}local D=table.getn(R)local E=1;if J~=f then for g=3,D do for F=E,C do E=E+1;local U=e[F]if b(K,U)~=f then T[F]=true elseif b(J,U)~=f then T[F]=true;x[v[F]]=R[g]break end end end end;if K>=d(1,E-1)then for F=E,C do E=E+1;if b(K,e[F])~=f then T[F]=true end end end;for z,A in pairs(H)do local y=S[z]if y~=nil and A~=nil and not T[y]then x[z]=A end end;return x end;local function V(W,X,Y,Z,_)local S={}local v={}for y,z in ipairs(X)do S[z]=y;table.insert(v,z)end;local C=table.getn(v)local a0={Encode=function(u)return t(u,v)end,Decode=function(u)return B(u,v,C)end,Diff=function(H,I)return G(H,I,v)end,Patch=function(H,R)return Q(H,R,v,S,C)end}if Y==nil then a0.Send=l;a0.Acknowledge=l;a0.RTT=function()return 0 end else local a1;local a2='NCRCT_'..W;_=_~=false;if a:IsServer()then if game.ReplicatedStorage:FindFirstChild(a2)then error('There is already an event with the given ID ('..a2 ..')')end;a1=Instance.new('RemoteEvent')a1.Parent=game.ReplicatedStorage;a1.Name=a2;local a3={}local function a4(a5,a6)local a7=a6.UserId;if a3[a7]~=nil and a3[a7][a5]~=nil then if j[a7]==nil then j[a7]={LastRttTime=-math.huge,RTT=0}end;local a8=j[a7]local a9=a3[a7][a5]if a9>a8.LastRttTime then local aa=os.clock()-a9;if a8.RTT==0 then a8.RTT=aa else a8.RTT=h*aa+i*a8.RTT end;a8.LastRttTime=a9 end;a3[a7][a5]=nil end end;a1.OnServerEvent:Connect(function(a6,ab)local u=ab[1]local a5=ab[2]if u==true then if a5~=nil then if _ then a4(a5,a6)end;if Z~=nil then Z(a5,a6,a0)end end else if u~=nil then if _ and a5~=nil then a1:FireClient(a6,{true,a5})end;Y(u,a5,u[1]~=true,a6,a0)end end end)a0.Send=function(u,a5,a6)if u==nil then return end;if _ and a5~=nil then local a7=a6.UserId;if a3[a7]==nil then a3[a7]={}end;if a3[a7][a5]==nil then a3[a7][a5]=os.clock()end end;a1:FireClient(a6,{u,a5})end;a0.Acknowledge=function(ac,a6)a1:FireClient(a6,{true,ac})end;a0.RTT=function(a6)local a8=j[a6.UserId]if a8~=nil then return a8.RTT end;return 0 end else a1=game.ReplicatedStorage:WaitForChild(a2)local a3={}local ad=-math.huge;local function a4(a5)if a3[a5]~=nil then local a9=a3[a5]if a9>ad then local aa=os.clock()-a9;if k==0 then k=aa else k=h*aa+i*k end;ad=a9 end;a3[a5]=nil end end;a1.OnClientEvent:Connect(function(ab)local u=ab[1]local a5=ab[2]if u==true then if a5~=nil then if _ then a4(a5)end;if Z~=nil then Z(a5,nil,a0)end end else if u~=nil then if _ and a5~=nil then a1:FireServer({true,a5})end;Y(u,a5,u[1]~=true,nil,a0)end end end)a0.Send=function(u,a5)if u==nil then return end;if _ and a5~=nil then if a3[a5]==nil then a3[a5]=os.clock()end end;a1:FireServer({u,a5})end;a0.Acknowledge=function(ac)a1:FireServer({true,ac})end;a0.RTT=function()return k end end end;return a0 end;return V