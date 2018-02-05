function [data,output]  = icem_read_micromed_trc(filename, readstim, inmv)
%--------------------------------------------------------------------------
% ICEM_READ_MICROMED_TRC reads Micromed .TRC file into matlab
% input: 
%       filename - path to .trc file
%       readstim - read only stimulation found in NOTE fields of header
%       (default = 0)
%       inmv     - do you need trace data in micro volts (default = 0) 
% output: 
%       data - cell (or cell array) with trace data.
%       output - header information
%
% example: 1 -  Read all EEG data from .trc file and convert EEG to microvolts:
%               [data header] = icem_read_micromed_trc("C://eeg1.trc", 0, 1)
% example: 2 -  Read only stimulation from .trc file (data variable is cell array of all stimulation):
%               [data header] = icem_read_micromed_trc("C://eeg1.trc", 1, 0)
%--------------------------------------------------------------------------
% author: Janis Hofmanis
%--------------------------------------------------------------------------
% bug correction (Radu): introduce MAX_LEN variable to read correctly the
% electrode names (line 207: MAX_LEN=640, different from MAX_CAN=256, used
% previously). Correction inspired from BiomedReader toolbox. Also changed the function name (added icem
% prefix, because the read_micromed_trc.m function also exists in Fieldtrip (Janis used it a starting point 
% I suppose)
% bug correction (Radu): permute electrodes, also inspired from BiomedReader

% ---------------- Opening File------------------
fid=fopen(filename,'rb');
if fid==-1
    error('Can''t open *.trc file')
end

% Read only stimulation
if ~exist('readstim','var')
    readstim = 0;
end
% Convert to microvolts (in double precision)
if ~exist('inmv','var')
    inmv = 0;
end

%------------------reading patient & recording info----------
fseek(fid,64,-1);
header.surname=strtrim(char(fread(fid,22,'int8'))');
header.name=strtrim(char(fread(fid,20,'int8'))');

fseek(fid,128,-1);
day=fread(fid,1,'int8');
if length(num2str(day))<2
    day=['0' num2str(day)];
else
    day=num2str(day);
end
month1=fread(fid,1,'int8');
switch month1
    case 1
        month='JAN';
    case 2
        month='FEB';
    case 3
        month='MAR';
    case 4
        month='APR';
    case 5
        month='MAY';
    case 6
        month='JUN';
    case 7
        month='JUL';
    case 8
        month='AUG';
    case 9
        month='SEP';
    case 10
        month='OCT';
    case 11
        month='NOV';
    case 12
        month='DEC';
end
header.day=day;
header.month=month;
header.year=num2str(fread(fid,1,'int8')+1900);

%------------------ Reading Header Info ---------
fseek(fid,175,-1);
header.Header_Type=fread(fid,1,'int8');
if header.Header_Type == 3 % Type 3 micromed format
    codestruct = {...
        'uint8' [1] 'Order';...
        };
    electrodestruct = {...
        'uint8' [1] 'Status';...
        'uint8'	 [1] 	'Type';...
        'int8'			 [1 6] 	'Positive_Input_Label';...
        'int8'				 [1 6] 'Negative_Input_Label';...
        'uint32'	 [1] 'Logic_Minimum';...
        'uint32'	 [1] 'Logic_Maximum';...
        'uint32' [1]	'Logic_Ground';...
        'int32'			 [1] 'Physic_Minimum';...
        'int32'			 [1] 'Physic_Maximum';...
        'uint16' [1] 	'Measurement_Unit';...
        'uint16' [1] 	'Prefiltering_HiPass_Limit';...
        'uint16' [1] 	'Prefiltering_HiPass_Type';...
        'uint16' [1] 	'Prefiltering_LowPass_Limit';...
        'uint16'	 [1] 'Prefiltering_LowPass_Type';...
        'uint16'	 [1] 'Rate_Coefficient';...
        'uint16'	 [1] 'Position';...
        'single'			 [1] 	'Latitude';...
        'single'			 [1] 	'Longitude';...
        'uint8'		 [1] 'Maps';...
        'uint8'		 [1] 'Average_Ref';...
        'int8'				 [1 32] 'Description';...
        'single'			 [1] 	'x';...
        'single'			 [1] 	'y';...
        'single'			 [1] 	'z';...
        'uint16'		 [1]        'Coordinate_Type'
        'uint8'		 [1 24] 'Reserved_2';...
        };
elseif header.Header_Type == 4 % Type 4 micromed format
    codestruct = {...
        'uint16' [1] 'Order';...
        };
    electrodestruct = {...
        'uint8' [1] 'Status';...
        'uint8'	 [1] 	'Type';...
        'int8'			 [1 6] 	'Positive_Input_Label';...
        'int8'				 [1 6] 'Negative_Input_Label';...
        'uint32'	 [1] 'Logic_Minimum';...
        'uint32'	 [1] 'Logic_Maximum';...
        'uint32' [1]	'Logic_Ground';...
        'int32'			 [1] 'Physic_Minimum';...
        'int32'			 [1] 'Physic_Maximum';...
        'uint16' [1] 	'Measurement_Unit';...
        'uint16' [1] 	'Prefiltering_HiPass_Limit';...
        'uint16' [1] 	'Prefiltering_HiPass_Type';...
        'uint16' [1] 	'Prefiltering_LowPass_Limit';...
        'uint16'	 [1] 'Prefiltering_LowPass_Type';...
        'uint16'	 [1] 'Rate_Coefficient';...
        'uint16'	 [1] 'Position';...
        'single'			 [1] 	'Latitude';...
        'single'			 [1] 	'Longitude';...
        'uint8'		 [1] 'Maps';...
        'uint8'		 [1] 'Average_Ref';...
        'int8'				 [1 32] 'Description';...
        'single'			 [1] 	'x';...
        'single'			 [1] 	'y';...
        'single'			 [1] 	'z';...
        'uint16'		 [1]        'Coordinate_Type'
        'uint8'		 [1 24] 'Reserved_2';...
        };
else
    error(['*.trc file is not Micromed System98 Header type 4 or 3 but: ' num2str(header.Header_Type)])
end

fseek(fid,138,-1);
header.Data_Start_Offset=fread(fid,1,'uint32');
header.Num_Chan=fread(fid,1,'uint16');
header.Multiplexer=fread(fid,1,'uint16');
header.Rate_Min=fread(fid,1,'uint16');
header.Bytes=fread(fid,1,'uint16');

fseek(fid,176+8,-1);
header.Code_Area=fread(fid,1,'uint32');
header.Code_Area_Length=fread(fid,1,'uint32');

fseek(fid,192+8,-1);
header.Electrode_Area=fread(fid,1,'uint32');
header.Electrode_Area_Length=fread(fid,1,'uint32');

fseek(fid,208+8,-1);
header.Note_Area=fread(fid,1,'uint32');
header.Note_Area_Length=fread(fid,1,'uint32');

fseek(fid,240+8,-1);
header.Segment_Area=fread(fid,1,'uint32');
header.Segment_Area_Length=fread(fid,1,'uint32');

fseek(fid,256+8,-1);
header.Impedance_B_Area=fread(fid,1,'uint32');
header.Impedance_B_Area_Length=fread(fid,1,'uint32');

fseek(fid,400+8,-1);
header.Trigger_Area=fread(fid,1,'uint32');
header.Tigger_Area_Length=fread(fid,1,'uint32');

newheader.Name = [header.surname ' ' header.name];
newheader.Date = [day '/' num2str(month1) '/' header.year];

newheader.SR = header.Rate_Min;
newheader.NbrCh = header.Num_Chan;

% Read time
fseek(fid,131,-1);
h=fread(fid,1,'int8');
min = fread(fid,1,'int8');
sec = fread(fid,1,'int8');

newheader.Start = [num2str(h) ':' num2str(min) ':' num2str(sec)];

MAX_CAN = 256;

% Read Order

c = memmapfile(filename,'Offset', header.Code_Area,'Format', codestruct,...
    'Repeat', MAX_CAN);

% Read electrodes
MAX_LAB=640;
m = memmapfile(filename,'Offset', header.Electrode_Area,'Format', electrodestruct,...
    'Repeat', MAX_LAB);
%

% Read impedance
impstruct = {...
    'uint8' [1] 'Positive';...
    'uint8'	 [1] 	'Negative';...
    };
i = memmapfile(filename,'Offset', header.Impedance_B_Area,'Format', impstruct,...
    'Repeat', MAX_CAN);

% Read notes
MAX_NOTE = 200;
notestruct = {...
    'uint32' [1] 'Starting_Sample';...
    'uint8'	 [1 40] 	'Description';...
    };
n = memmapfile(filename,'Offset', header.Note_Area,'Format', notestruct,...
    'Repeat', MAX_NOTE);
notedata = n.Data;

sts = vertcat(notedata(:).Starting_Sample);

notedata = notedata(sts>0);

% Read Segments
MAX_SEG = 100;
segstruct = {...
    'uint32' [1] 'Time';...
    'uint32'	 [1] 	'Sample';...
    };
seg = memmapfile(filename,'Offset', header.Segment_Area,'Format', segstruct,...
    'Repeat', MAX_SEG);

newheader.CODE_DATA = c.Data;
newheader.EL_DATA = m.Data;
newheader.IMP_DATA = i.Data;
newheader.NOTE_DATA = notedata;
newheader.SEG_DATA = seg.Data;
newheader.OldHeader = header;

%----------------- Ordering Header info -----
% newheader = changeorder(newheader);

[fdir fname] = fileparts(filename);
data = {};
output = newheader;
%% If this is just a segment of real data
%  if (newheader.SEG_DATA(1).Time ~= 0)
%      fprintf('\nSegement file: %s\n%s: %s\n\n',fname, newheader.Name, newheader.Date);
%      return;
%
%  end

%----------------- Read Trace Data ----------

fprintf('Reading: %s\n%s: %s\n',fname, newheader.Name, newheader.Date);

% determine the number of samples
fseek(fid,header.Data_Start_Offset,-1);
datbeg = ftell(fid);
fseek(fid,0,1);
datend = ftell(fid);
header.Num_Samples = (datend-datbeg)/(header.Bytes*header.Num_Chan);
if rem(header.Num_Samples, 1)~=0
    warning('Rounding off the number of samples');
    header.Num_Samples = floor(header.Num_Samples);
end
% output the header

dv = datevec(newheader.Start);
ptoctime = header.Num_Samples/header.Rate_Min;
dv(end) = dv(end)+ptoctime;
newheader.End = datestr(datenum(dv),'HH:MM:SS.FFF');
% newheader.OldHeader = header;

output = eegdata_add_elnames2patientinfo(newheader);

typest = 'uint16';
switch header.Bytes
    case 1
        typest = 'uint8';
    case 2
        typest = 'uint16';
    case 4
        typest = 'uint32';
    otherwise
        error(['*.trc file contains unknown data type: ' num2str(header.Bytes)]);
end
if readstim == 1
    sinfo = getStimulations(newheader);
    fprintf('Nr. of stimulations: %d\n\n',length(sinfo));
    
    
    output.sinfo = sinfo;
    for i=1:length(sinfo)
        begsample = sinfo(i).data(1);
        endsample = sinfo(i).data(2);
        
        fseek(fid,header.Data_Start_Offset,-1);
        fseek(fid, header.Num_Chan*header.Bytes*(begsample-1), 0);
        
        data{i} = fread(fid, [header.Num_Chan endsample-begsample+1], typest);
    end
    
    %     data = eegdata_micromed2mvolts(data,output);
    
else
    begsample = 1;
    endsample = header.Num_Samples;
    fseek(fid,header.Data_Start_Offset,-1);
    fseek(fid, header.Num_Chan*header.Bytes*(begsample-1), 0);
    data = {fread(fid, [header.Num_Chan endsample-begsample+1], ['*' typest])};
    
end

if inmv == 1
    data = eegdata_micromed2mvolts(data,output);
end

fclose(fid);

end

function sinfo = getStimulations(header)

begadd = 5;
aftadd = 15;
notedata = header.NOTE_DATA;
a = 1;
sinfo = struct('descr',{},'amp',{},'freq',{},'text',{},'data',{});

for i=1:length(notedata)
    
    des = strtrim(char(notedata(i).Description));
    
    stimind(1) = any(regexp(des,'mA'));
    stimind(2) = any(regexp(des,'Hz'));
    stimind(3) = any(regexp(des,'Train'));
    
    
    if sum(stimind) > 1
        
        
        temp = regexp(des,'(?<text>())(?<amp>(\d\.\d))mA.*(?<freq>( \d+\.\d))Hz','names');
        if ~isempty(temp)
            try
                tinfo.descr = des;
                tinfo.amp = str2num(temp.amp);
                tinfo.freq = str2num(temp.freq);
                tinfo.text =  char(des(1:regexp(des,'\d\.\dmA')-2));
                [token, remain] = strtok(tinfo.text, '-');
                
                if ~isempty(remain)
                    p1 = strtrim(token);
                    p2 = strtrim(remain(2:end));
                    
                    if p1(1)==p2(1) %&& ~isempty(str2double(p1(end)))
                        tinfo.data = [notedata(i).Starting_Sample-header.SR*begadd notedata(i).Starting_Sample+header.SR*aftadd];
                        sinfo(a) = tinfo;
                        a = a +1;
                    end
                end
            catch
                warning(['Problems with stim comment: ' des]);
            end
        end
    end
    
end

end

function info = eegdata_add_elnames2patientinfo(header)

elind = [header.EL_DATA.Status]; % janis
names = {header.EL_DATA(elind==1).Positive_Input_Label}; % janis

position=[header.EL_DATA(find([header.EL_DATA.Status]==1)).Position]+1; % radu !!
[~,iposition]=sort(position); % radu !!
names = names(iposition); % radu !!
namest = cellfun(@(a)char(a(a~=0)),names,'UniformOutput',0)';

info = header;
info.Names = namest;

end

function info = changeorder(header)


info = header;
orind = [header.CODE_DATA.Order]';
orind = orind(1:header.NbrCh)+1;
elind = logical([header.EL_DATA.Status]);

elindt = find(elind)';

so = sort(orind);


if sum(so~=elindt)~=0
    warning('Something wrong with the ordering. Electrodes not ordered (Can produce problems with el names)');
else
    info.EL_DATA(elind) = header.EL_DATA(orind);
end

end

% function data = eegdata_micromed2mvolts(data,header)
% 
% elind = logical([header.EL_DATA.Status]);
% lgmat = [header.EL_DATA(logical(elind)).Logic_Ground];
% lmaxmat = [header.EL_DATA(logical(elind)).Logic_Maximum];
% lminmat = [header.EL_DATA(logical(elind)).Logic_Minimum];
% physmax = [header.EL_DATA(logical(elind)).Physic_Maximum];
% physmin = [header.EL_DATA(logical(elind)).Physic_Minimum];
% 
% if sum(max(abs(data{1}))<physmax(1)+500) == size(data{1},2)
%     warning('Your data seems to be in microvolts already. Do not call this second time.');
%     return;
% end
% 
% for i=1:length(data)
%     [n m] = size(data{i});
%     %     data{i} = (data{i}-double(lgmat(1)))./(double(lmaxmat(1)-lminmat(1))+1).*double(physmax(1)-physmin(1));
%     data{i} = (double(data{i})-double(repmat(lgmat',1,m)))./(double(repmat(lmaxmat',1,m)-repmat(lminmat',1,m))+1).*double(repmat(physmax',1,m)-repmat(physmin',1,m));
% end
% end
