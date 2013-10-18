% #!/usr/bin/octave -q
function dpf2dpv(varargin)
% Convert data-per-face (DPF) to data-per-vertex (DPV) files, redistributing the
% face quantities to their vertices. Assumes that the quantity is
% homogeneously distributed within face and that the redistribution is conceptually
% correct.
%
% Usage:
% dpf2dpv(srffile,dpffile,dpvfile)
% 
% srffile : Input reference surface file, in ASCII format.
% dpffile : File with the data-per-face. Has to have the
%           same number of faces as the reference surface file.
% dpvfile : File to be created, with the quantities redistributed
%             to the vertices.
%
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jun/2011
% http://brainder.org

% Do some OCTAVE stuff, but use TRY to ensure MATLAB compatibility
try
    % Get the inputs
    varargin = argv();
    nargin = numel(varargin);

    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);

    % Print usage if no inputs are given
    if isempty(varargin) || strcmp(varargin{1},'-q'),
        fprintf('Convert data-per-face (DPF) to data-per-vertex (DPV) files, redistributing the\n');
        fprintf('face quantities to their vertices. Assumes that the quantity is\n');
        fprintf('homogeneously distributed within face and that the redistribution is conceptually\n');
        fprintf('correct.\n');
        fprintf('\n');
        fprintf('Usage:\n');
        fprintf('dpf2dpv <srffile.srf> <dpffile.dpf> <dpvfile.dpv>\n');
        fprintf('\n');
        fprintf('srffile : Input reference surface file, in ASCII format.\n');
        fprintf('dpffile : File with the data-per-face. Has to have the\n');
        fprintf('          same number of faces as the reference surface file.\n');
        fprintf('dpvfile : File to be created, with the quantities redistributed\n');
        fprintf('          to the vertices.\n');
        fprintf('\n');
        fprintf('_____________________________________\n');
        fprintf('Anderson M. Winkler\n');
        fprintf('Yale University / Institute of Living\n');
        fprintf('Jun/2011\n');
        fprintf('http://brainder.org\n');
        return;
    end
end

% Get the inputs (varargin has to be used so that it works in OCTAVE)
srffile = varargin{1};
dpffile = varargin{2};
dpvfile = varargin{3};

% Read the reference surface
[vtx,fac] = srfread(srffile);
nV = size(vtx,1);
nF = size(fac,1);

% Read the data per face file
dpf = dpxread(dpffile);

% Test if the number of faces is the same in the files
if nF ~= numel(dpf),
    error('Reference surface and data per face have a different geometries');
end

% For speed, divide the dpf by 3.
dpf3 = dpf/3;

% Redistribute!
dpv = zeros(nV,1);
for f = 1:nF,
    dpv(fac(f,:)) = dpv(fac(f,:)) + dpf3(f);
end

% Save the result
fid = fopen(dpvfile,'w');
fprintf(fid,'%0.3d %g %g %g %0.16f\n',[(0:nV-1)' vtx dpv]');
fclose(fid);
