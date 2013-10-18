% #!/usr/bin/octave -q
function applyolp(varargin)
% Produces an interpolated DPF file when the overlapping
% geometries source and target spheres (OLP table) are known.
% The OLP file is generated during the areal interpolation.
% 
% Usage: 
% applyolp(olpfile,srffile,dpffile1,dpffile2,update,reverse)
% 
% Inputs:
% olpfile  : Overlap table (OLP), as saved during the areal
%            interpolation.
% srffile  : Reference surface file (target), from which the face indices
%            are going to be taken.
% dpffile1 : DPF file containing the areal quantities that will
%            be transferred to the target geometry.
% dpffile2 : DPF file to be created, containing the interpolated areal
%            quantities.
% update   : If true, update the dpffile2, rather than creating it (therefore
%            it must exist already).
% reverse  : If true, does a reverse interpolation
% 
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Aug/2011
% http://brainder.org

% OCTAVE stuff, with TRY to ensure MATLAB compatibility
try
    % Get the inputs
    varargin = argv();

    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);

    % Print usage if no inputs are given
    if isempty(varargin) || strcmp(varargin{1},'-q'),

        fprintf('\n');
        fprintf('Produces an interpolated DPF file when the overlapping\n');
        fprintf('geometries source and target spheres (OLP table) are known.\n');
        fprintf('The OLP file is generated during the areal interpolation.\n');
        fprintf('\n');
        fprintf('Usage: \n');
        fprintf('applyolp <olpfile> <srffile> <dpffile1> <dpffile2> [update] [reverse]\n');
        fprintf('\n');
        fprintf('Inputs:\n');
        fprintf('olpfile  : Overlap table (OLP), as saved during the areal\n');
        fprintf('           interpolation.\n');
        fprintf('srffile  : Reference surface file (target), from which the face indices\n');
        fprintf('           are going to be taken.\n');
        fprintf('dpffile1 : DPF file containing the areal quantities that will\n');
        fprintf('           be transferred to the target geometry.\n');
        fprintf('dpffile2 : DPF file to be created, containing the interpolated areal\n');
        fprintf('           quantities.\n');
        fprintf('update   : If true, update the dpffile2, rather than creating it (therefore\n');
        fprintf('           it must exist already).\n');
        fprintf('reverse  : If true, does a reverse interpolation\n');
        fprintf('\n');
        fprintf('_____________________________________\n');
        fprintf('Anderson M. Winkler\n');
        fprintf('Yale University / Institute of Living\n');
        fprintf('Aug/2011\n');
        fprintf('http://brainder.org\n');
        return;
    end
end

% Some defaults
d.update  = false;
d.reverse = false;

% Get inputs
fields = {'olpfile','srffile','dpffile1','dpffile2','update','reverse'};
if nargin < 4 || nargin > 6,
    error('Invalid number of arguments');
end
for a = 1:nargin,
    d.(fields{a}) = varargin{a};
end
d.update  = eval(d.update);
d.reverse = eval(d.reverse);


% Read the table
[status,result] = system(sprintf('wc -l %s', d.olpfile));
nL = str2double(strtok(result,' '));
fid = fopen(d.olpfile,'r');
table0 = fscanf(fid,'%f',5*nL);
fclose(fid);
table = reshape(table0,[5 nL])';

% Read the reference surface
[vtx,fac] = srfread(d.srffile);
nF2 = size(fac,1);

% Read the source DPF file
dpf1 = crvread(d.dpffile1);

% If update, load the file
if d.update,
    dpf2 = crvread(d.dpffile2);
    if d.reverse,
        flist2 = unique(table(:,1))';
    else
        flist2 = unique(table(:,2))';
    end
else
    dpf2 = zeros(nF2,1);
    flist2 = 1:nF2;
end

% Applies the interpolation, as saved in the table
if d.reverse,
    wght = dpf1(table(:,2)).*table(:,3)./table(:,5);
    for f2 = flist2,
        dpf2(f2) = sum(wght(table(:,1) == f2));
    end
else
    wght = dpf1(table(:,1)).*table(:,3)./table(:,4);
    for f2 = flist2,
        dpf2(f2) = sum(wght(table(:,2) == f2));
    end
end

% Save the resulting interpolated DPF file
dpf2 = [(0:nF2-1)' fac dpf2];
fid = fopen(d.dpffile2,'w');
fprintf(fid,'%0.3d %g %g %g %0.16f\n',dpf2');
fclose(fid);
