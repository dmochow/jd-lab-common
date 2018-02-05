function Xout = zeroBadSamples(X,Q,xtent)
if nargin<3, xtent=0; end
if nargin<2, Q=4; end
if nargin<1, error('Need at least one argument for zeroBadSamples'); end

if size(X,1)>size(X<2), X=X.'; end % electrodes in row dimension
[~,nSamples]=size(X);

%%
%stds=std(X,[],2);
%isBad=abs(X)>repmat(Q*stds,1,nSamples);

meds=median(abs(X),2);
thresh=meds/0.6745*Q;
isBad=abs(X)>repmat(thresh,1,nSamples);

[row,col]=find(isBad);

N=size(row,1);
ROW=repmat(row,1,2*xtent+1);
COL=repmat(col,1,2*xtent+1);
COL=COL+repmat(-xtent:xtent,N,1);

rrow=ROW(:);
ccol=COL(:);

validInds= find(ccol>0 & ccol<=nSamples);
rrow=rrow(validInds);
ccol=ccol(validInds);

finalInds=sub2ind(size(X),rrow,ccol);

Xout=X;
Xout(finalInds)=0;

