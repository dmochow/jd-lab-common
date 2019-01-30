function [sems,mus,stds] = nansem( x,dim )
%SEMS=NANSEM(X,[DIM]); standard errors of the mean
%   compute standard errors of the mean of x along dimension dim
if nargin<2, dim=ndims(x); end
%lendim=size(x,dim);
lendim=sum(~isnan(x),dim);
sems=nanstd(x,[],dim)./sqrt(lendim);
stds=nanstd(x,[],dim);
mus=nanmean(x,dim);  % get means while at it
end

