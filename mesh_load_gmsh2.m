function m = mesh_load_gmsh2( varargin )
% load a Gmsh mesh file, including binaries
%
% USAGE:
% m=mesh_load_gmsh(fn);
%
% !only triangles and tetrahedra are supported as element types!
%
% See http://www.geuz.org/gmsh/doc/texinfo/gmsh-full.html#SEC56 for
% documentation of the file format.
% 
% Andre Antunes 29 Oct 2014

tic

fn = varargin{1};

if nargin<1
   [fname, pname]= uigetfile('*.msh');
   if isequal(fname,0) || isequal(pname,0); return; end;
   fn = [pname fname];
end;

if ~ischar(fn)
    error(['invalid filename:' fn]);
end

if ~exist(fn, 'file')
    error(['file does not exist:' fn]);
end



m.node_data = {};
m.element_data = {};
m.element_node_data = {};

fid=fopen(fn);

tline = fgetl(fid);
if ~strcmp('$MeshFormat', tline)
    error('Start tag $MeshFormat expected');
end;

% parse 2nd line: version.minor_version is_binary byte_size
tline = fgetl(fid);
m.version = sscanf(tline, '%d.%d %d %d');
if m.version(1) ~= 2
    warning(['msh version is ' num2str(m.version(1)) '.' num2str(m.version(2)) '. Only version 2.x was tested']);
end
if m.version(4) ~= 8
    error(['expected to read 8 byte precision, but encountered: ' num2str(m.version(4))]);
end

is_binary = m.version(3);

if is_binary
    endianess = fread(fid, 1, 'int');
    if (endianess ~= 1)
        error('Endianess in binary file is different than 1. I cant procceed..\n Was this file created in windows?');
    end
    a = fread(fid, 1, 'char'); % read end of line ( should be ascii 010)
    if a ~= 10; error(['Expected LF (new line), but I read ASCII:' a]); end
end

tline = fgetl(fid);
if ~strcmp('$EndMeshFormat', tline)
    error('End tag $EndMeshFormat expected');
end;


%% read nodes
tline = fgetl(fid);
if strcmp('$Nodes', tline)
    if is_binary
        m = read_nodes_binary(m, fid);
    else
        m = read_nodes(m, fid);
    end
else
    error('Start tag $Nodes expected');
end;


%% read elements
tline = fgetl(fid);
if strcmp('$Elements', tline)
    if is_binary
        m = read_elements_binary(m, fid);
    else
        m = read_elements(m, fid);
    end
else
    error('Start tag $Elements expected');
end;

%% read data ($NodeData, $ElementData, $ElementNodeData)
tline = fgetl(fid);
while ~feof(fid)
    if is_binary
        if strcmp('$NodeData', tline)
            m.node_data{end+1} = read_data_binary(fid, tline);
        elseif strcmp('$ElementData', tline)
            m.element_data{end+1} = read_data_binary(fid, tline);
        elseif strcmp('$ElementNodeData', tline)
            m.element_node_data{end+1} = read_data_binary(fid, tline);
        else
            error(['Unsupported field:' tline]);
        end
    else
        if strcmp('$NodeData', tline)
            m.node_data{end+1} = read_data(fid, tline);
        elseif strcmp('$ElementData', tline)
            m.element_data{end+1} = read_data(fid, tline);
        elseif strcmp('$ElementNodeData', tline)
            warning('$ElementNodeData is not supported, will read only data from the first node!!');
            m.element_data{end+1} = read_data(fid, tline);
        else
            error(['Unsupported field:' tline]);
        end
    end
    tline = fgetl(fid);
end
    
m.node_data = m.node_data';
m.element_data = m.element_data';
m.element_node_data = m.element_node_data';

fprintf('Number of Points             : %d\n', size(m.points,1));
fprintf('Number of Triangles          : %d\n', size(m.triangles,1));
fprintf('Number of Triangle Regions   : %d\n', size(unique(m.triangle_regions),1));
fprintf('Number of Tetrahedra         : %d\n', size(m.tetrahedra,1));
fprintf('Number of Tetrahedron Regions: %d\n', size(unique(m.tetrahedron_regions),1));
 
toc

function m = read_nodes_binary(m, fid)
    % get number of nodes (this line is in ascii)
    tline = fgetl(fid);
    number_of_nodes = sscanf(tline,'%d');
    if ~isnumeric( number_of_nodes )
        error('number of nodes is not a number');
    end
   
    % skip first column which contains order of the first element (usually 1)
    a = fread(fid, 1, 'int');
    if a ~= 1; error(['first node should be numbered 1, but I read:', num2str(a)]); end
    
    % read 3 double columns, skipping 4 bytes after each read
    m.points = fread(fid, [3 number_of_nodes ], '3*double', 4)';
    
    % go back 4 bytes
    fseek(fid, -4, 'cof');
    
    % sometimes there is an end of line after $Nodes, sometimes there is
    % not... handle that
    read_LF(fid);
   
    % confirm last line
    tline = fgetl(fid);
    if ~strcmp('$EndNodes', tline)
        error('End tag $EndNodes expected'); 
    end


    
function m = read_nodes(m, fid)
    % get number of nodes
    tline = fgetl(fid);
    number_of_nodes = sscanf(tline,'%d');
    if ~isnumeric( number_of_nodes )
        error(['number of nodes is not a number']);
    end
    
    pts = textscan(fid, '%*d %f %f %f\n');
    m.points = [pts{1} pts{2} pts{3}];
    
    if size(m.points,1) ~= number_of_nodes
        error('read incorrect number of node data');
    end

    % read end line
    tline = fgetl(fid);
    if ~strcmp('$EndNodes', tline)
        error('End tag $EndNodes expected'); 
    end
    
    
    
function m = read_elements_binary(m, fid)
    % get number of elements
    tline = fgetl(fid);
    number_of_elements = sscanf(tline,'%d');
    if ~isnumeric( number_of_elements )
        error('number of elements is not a number');
    end
    
    % read everything as triangles (some data will not be read). Some tetrahedra
    % data will be read and ordered as a triangle table, but I will fix this
    % later.
    tr = fread(fid, [9 number_of_elements], '*int32');
    
    % find the first table element that is not a triangle. The total number of
    % triangles is this number minus one
    nr_triangles = find( tr(1,:) ~= 2, 1, 'first') - 1;
    
    % exception when all elements are triangles
    if sum(tr(1,:) == 2) == number_of_elements
        nr_triangles = number_of_elements;
    end
    
    nr_tetrahedra = number_of_elements-nr_triangles;
    
    % write data to struct
    m.triangles = tr(7:9, 1:nr_triangles)';
    m.triangle_regions = tr(6, 1:nr_triangles)';
    
    % I still need to read these bytes (remaining tetrahedra information).
    tetr_rem = fread(fid, nr_tetrahedra, '*int32');
    
    % sometimes there is an end of line after $Elements, sometimes there is
    % not... handle that
    read_LF(fid);
        
    % now, concatenate tetrahedra that were on the triangle table and reshape
    tetr = tr(:);   % flatten
    tetr = tetr(9*nr_triangles+1:end);  % select tetrahedra data from the array
    tetr = [tetr; tetr_rem];    % append with leftover tetrahedra
    tetr = reshape(tetr, [10 nr_tetrahedra])'; % reshape with correct table format
    
    % write data to struct
    m.tetrahedra = tetr(:, 7:10);
    m.tetrahedron_regions = tetr(:, 6);
    
    % read end line
    tline = fgetl(fid);
    if ~strcmp('$EndElements', tline)
        error(['End tag $EndElements expected, but I read: ' tline]);
    end
    % beat this, if you can
 
    
    
function m = read_elements(m, fid)
    % get number of elements
    tline = fgetl(fid);
    number_of_elements = sscanf(tline,'%d');
    if ~isnumeric( number_of_elements )
        error('number of elements is not a number');
    end
    
    % only works if mesh contains only triangles / tetrahedra
    % read all elements
    c = textscan(fid,'%*d %d %*d %d %*d %d %d %d %d\n');
    if size(c{1},1) ~= number_of_elements
        error(['number of elements read does not correspond to ' num2str(number_of_elements)]);
    end
    
	% Separate triangles from tetrahedra
    tri = c{1}==2;
    tetr = c{1}==4;
    m.triangles = [c{3}(tri) c{4}(tri) c{5}(tri)];
    m.tetrahedra = [c{3}(tetr) c{4}(tetr) c{5}(tetr) c{6}(tetr)];
    m.triangle_regions = c{2}(tri);
    m.tetrahedron_regions = c{2}(tetr);
    
    % read end line
    tline = fgetl(fid);
    if ~strcmp('$EndElements', tline)
        error(['End tag $EndElements expected, but I read: ' tline]);
    end


    

function data = read_data_binary(fid, data_type)
    
    % read string tags (including name)
    tline = fgetl(fid);
    if sscanf(tline,'%d') ~= 1; error('nr_string_tags should always be 1'); end
    name = fgetl(fid);

    % read real tags
    tline = fgetl(fid);
    if sscanf(tline,'%d') ~= 1; error('nr_real_tags should always be 1'); end
    tline = fgetl(fid);
    
    % read integer tags (size of data)
    tline = fgetl(fid);
    nlines = sscanf(tline,'%d');
    if nlines ~= 3 && nlines ~= 4
        error('nr_int_tags should always be 3 or 4');
    end
    
    for i=1:nlines
        tline = fgetl(fid);
        int_tags(i) = sscanf(tline, '%d');
    end;
    
    % nr of field components (1, 3, 9) for scalar, vector, tensor
    comp = int_tags(2);
    nr_data = int_tags(3);
    
    %fseek(fid, pos, 'bof');
    %pos = ftell(fid);

   
    
    
    % read float data, skipping 8 bytes at the end
    if strcmp(data_type, '$ElementNodeData')
        % for $ElementData and $ElementNodeData, it is written as:
        % elm-number number-of-nodes-per-element value
        % where value has comp*number_of_nodes_per_element value
        % since we only write to tetrahedra, I will assume there are no triangles
        % with $ElementNodeData

        % read first two columns
        fread(fid, 2, '*uint32');
        datatable = fread(fid, [4*comp nr_data], [num2str(4*comp) '*double'], 8)';
        fseek(fid, -8, 'cof');
    elseif strcmp(data_type, '$NodeData') || strcmp(data_type, '$ElementData')
        fread(fid, 1, '*uint32');
        datatable = fread(fid, [comp nr_data], [num2str(comp) '*double'], 4)';
        fseek(fid, -4, 'cof');
    else
        error('still need to code other data types');
    end
                
    
    
     % build struct with data
    if length(name) > 2
        data.name = name(2:end-1);
    else
        data.name = '';
    end
    
    data.data = datatable;
    
    % read last line
    tline = fgetl(fid);
    if ~strcmp(['$End' data_type(2:end)], tline)
        error(['End tag $End' data_type ' expected']);
    end

 

function data = read_data(fid, data_type)

    % read string tags (including name)
    tline = fgetl(fid);
    if sscanf(tline,'%d') ~= 1; error('nr_string_tags should always be 1'); end
    name = fgetl(fid);

    % read real tags
    tline = fgetl(fid);
    if sscanf(tline,'%d') ~= 1; error('nr_real_tags should always be 1'); end
    tline = fgetl(fid);
    
    % read integer tags (size of data)
    tline = fgetl(fid);
    nlines = sscanf(tline,'%d');
    if nlines ~= 3 && nlines ~= 4
        error('nr_int_tags should always be 3 or 4');
    end
    
    for i=1:nlines
        tline = fgetl(fid);
        int_tags(i) = sscanf(tline, '%d');
    end;
    
    comp = int_tags(2);

    % read data
    t_str = repmat(' %f', 1, comp);
    c = textscan(fid, ['%*d' t_str '\n']);
    if size(c{1},1) ~= int_tags(3)
        error(['number of data lines read does not correspond to ' num2str(int_tags(3))]);
    end
    
    % build struct with data
    if length(name) > 2
        data.name = name(2:end-1);
    else
        data.name = '';
    end
    
    data.data = [];
    for i=1:comp
        data.data = [data.data c{i}];
    end
        
    % read last line
    tline = fgetl(fid);
    if ~strcmp(['$End' data_type(2:end)], tline)
        error(['End tag $End' data_type ' expected']);
    end

    
function read_LF(fid)
    a = fread(fid, 1, 'char');
    if a == 10
        disp('LF found, but I should be able to handle it');
    elseif a == 36
        % go back 1 byte, I'm reading a "$" character
        fseek(fid, -1, 'cof');
    else
        error(['Dont know what to do with this: ' a]);
    end
    