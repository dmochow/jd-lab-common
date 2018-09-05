function Xout = regressOut(X,Y,override)
% XOUT=REGRESSOUT(X,Y,override)
% linearly regress out the components in matrix Y from the matrix X
%
% assumes channels in row dimension, time in column dimension

% put into space-time format
% if size(X,1)>size(X,2), X=X.'; warning('transposing X'); end
% if size(Y,1)>size(Y,2), Y=Y.'; warning('transposing Y'); end

if nargin<3, override=0; end

if ~override
    if size(X,1)>size(X,2) || size(Y,1)>size(Y,2)
        X=X.';
        Y=Y.';
        warning('transposing X and Y');
    end
end
% check number of time samples
if size(X,2)~=size(Y,2), error('number of samples in X must equal that in Y'); end;

A=X*pinv(Y);
Xout=X-A*Y;