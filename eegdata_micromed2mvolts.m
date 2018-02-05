function data = eegdata_micromed2mvolts(data,header)
% EEGDATA_MICROMED2MVOLTS converts data from micromed format to microvolts.
% Data and header need to be in Janis format, given by 
% his read_micromed_trc.m, not the FieldTrip Mariska's function with the 
% same name!!)
%
% inputs:
% data - SEEG data in a cell array of N elements corresponding to N
%   stimulation sessions
% header - the corresponding header
% 
% output:
% data - converted data
%
% version notes: 
% help written by RR, 08/04/2014
% bug correction (RR, 21/05/2015): replaced logical by ==1 (line 26) in order
% to eliminate electrode status ~=1 (seem to appear in the micromed header; 
% according to BiomedReader toolbox, the status falg should only be 0 or 1, 
% for not acquired / acquired), so this should work.

convmV=0;
if ~iscell(data)
    data={data};
    convmV=1;
end

elind = [header.EL_DATA.Status]==1;
lgmat = [header.EL_DATA(logical(elind)).Logic_Ground];
lmaxmat = [header.EL_DATA(logical(elind)).Logic_Maximum];
lminmat = [header.EL_DATA(logical(elind)).Logic_Minimum];
physmax = [header.EL_DATA(logical(elind)).Physic_Maximum];
physmin = [header.EL_DATA(logical(elind)).Physic_Minimum];

if sum(max(abs(data{1}))<physmax(1)+500) == size(data{1},2)
   warning('Your data seems to be in microvolts already. Do not call this second time.');
   return;
end

for i=1:length(data)
    [n m] = size(data{i});
%     data{i} = (data{i}-double(lgmat(1)))./(double(lmaxmat(1)-lminmat(1))+1).*double(physmax(1)-physmin(1));
    data{i} = (double(data{i})-double(repmat(lgmat',1,m)))./(double(repmat(lmaxmat',1,m)-repmat(lminmat',1,m))+1).*double(repmat(physmax',1,m)-repmat(physmin',1,m));
end

if convmV==1,
    data=cell2mat(data);
end
