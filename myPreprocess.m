function dataOut = myPreprocess( dataIn , opts)
% preprocess input eeg data
%  allow for various pre-processing options
%  includes option for robust pca

if nargin<2
    opts.Q1=4;
    opts.Q2=4;
    opts.zero=1;
    opts.xtent=12;
    opts.showSvd=0;
    opts.nChan2Keep=128;
    opts.rpca=1;
    opts.fs=512;
    opts.fsref=256;
    opts.locfile='BioSemi64.loc'; % wild guess
    opts.chanlocs=[];
end

if ~isfield(opts,'Q1')
    opts.Q1=4;
end

if ~isfield(opts,'Q2')
    opts.Q2=4;
end

if ~isfield(opts,'zero')
    opts.zero=1;
end

if ~isfield(opts,'notch60')
    opts.notch60=1;
end

if ~isfield(opts,'xtent')
    opts.xtent=12;
end

if ~isfield(opts,'show')
    opts.show=1;
end

if ~isfield(opts,'nChan2Keep')
    opts.nChan2Keep=64;
end

if ~isfield(opts,'fs')
    opts.fs=512;
end

if ~isfield(opts,'fsref')
    opts.fsref=256;
end

if ~isfield(opts,'virtualeog')
    opts.virtualeog=[];
end

Q1=opts.Q1; Q2=opts.Q2; zero=opts.zero; xtent=opts.xtent;
nChan2Keep=opts.nChan2Keep;

fs=opts.fs;
fsref=opts.fsref;
prependLen=round(5*fs);

% ensure space-time format
dataIn=forceSpaceTime(dataIn);
channels=1:nChan2Keep;
dataIn=dataIn(channels,:);

% nChannels=size(dataIn,1);
% nSamples=size(dataIn,2);




%%
fl=opts.fl;
if isfield(opts,'fh')
    fh=opts.fh;
    [b,a]=butter(4,[fl/(fs/2) fh/(fs/2)] ,'bandpass');
    %[b,a]=butter(2,[fl/(fs/2) fh/(fs/2)] ,'bandpass');
else
    [b,a]=butter(2,fl/(fs/2) ,'high');
end
dataIn=cat(2,zeros(nChan2Keep,prependLen),dataIn);
dataOut=filter(b,a,dataIn,[],2);
dataOut=dataOut(:,prependLen+1:end);

%%
if opts.notch60
    [b,a]=butter(4,[58/(fs/2) 62/(fs/2)] ,'stop');
    dataOut=cat(2,zeros(nChan2Keep,prependLen),dataOut);
    dataOut=filter(b,a,dataOut,[],2);
    dataOut=dataOut(:,prependLen+1:end);
end



%% common mean subtraction
dataOut=dataOut-repmat(mean(dataOut,1),nChan2Keep,1);


%% downsampling
dsr=round(fs/fsref);
dataOut =( downsample(dataOut.', dsr) ).'; % data in in space time but downsample.m wants time space

%%
% run robust pca if desired
if opts.rpca
    %dataOut(isnan(dataOut))=1e3; % approximate NaN with this number (?!)
    dataOut=forceSpaceTime(dataOut)'; % change to time-space
    [A_hat E_hat iter] = inexact_alm_rpca(dataOut);
    dataOut=forceSpaceTime(A_hat); % back to space-time
end

[dataOut,gind] = nanBadChannels(dataOut,Q1,Q2,zero);
dataOut = nanBadSamples(dataOut,Q1,Q2,zero,xtent);

if ~isempty(opts.virtualeog)
    Xref=opts.virtualeog.'*dataOut;
    dataOut=regressOut(dataOut,Xref);
end
%%
if opts.showSvd
    [U,S,V]=svd(dataOut',0);
    figure;
    for c=1:20
        subplot(4,5,c)
        if isempty(opts.locfile)
            topoplot(V(:,c),opts.chanlocs,'electrodes','labels'); colormap('jet');
        else
            topoplot(V(:,c),opts.locfile,'electrodes','labels'); colormap('jet');
        end
    end
    drawnow
end



end

