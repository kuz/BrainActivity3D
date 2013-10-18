% #!/usr/bin/octave -q
function platonic(varargin)
% Create one of the five Platonic polyhedra (tetrahedron, hexahedron,
% octahedron, dodecahedron and icosahedron) OR a geodesic sphere by
% progressive subdivision of the faces of the polyhedra with triangular
% faces (tetrahedron, octahedron and icosahedron). Icosahedron is the
% recommended choice for a geodesic sphere (icosphere).
%
% Usage:
% platonic(fname,pname,meas,mval,trans,rnd)
% fname : File to be created, in OBJ format.
% pname : Platonic polyhedron to be created. Choose one of the following:
%         'tetra', 'hexa', 'octa', 'dode' or 'ico'.
% meas  : Measurement that have its value defined. Choose one of the following:
%         'e' : Edge length                   'v' : Volume
%         'af': Area of the face              'cr': Circumradius
%         'at': Total area                    'ir': Inradius
%         Alternatively, use 'sph' to subdivide each triangular face MVAL
%         times and project the vertices to the surface of a sphere of
%         radius 1.
% mval  : Value defined for the measurement (MEAS) or number of iteractions
%         for subdivision of the faces.
% trans : Optional. Once the polyhedron/sphere is constructed with the parameters
%         given by meas and mval, apply a transformation to position it in the 3D
%         space and possibly scale it. TRANS can be a a singleton [x] specifying a
%         scaling factor, a triplet [x y z] specifying the new center, or a
%         full 4x4 affine matrix defining translation, rotation, scaling and shear.
% rnd   : Perturb the locations of the vertices if set as true.
%
% Important: Use placemakers for non-given arguments if another is placed later.
%
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jan/2011

% Do some OCTAVE stuff, but use TRY to ensure MATLAB compatibility
try
    % Get the inputs
    varargin = argv();

    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);

    % Print usage if no inputs are given
    if isempty(varargin) || strcmp(varargin{1},'-q'),
        fprintf('Create one of the five Platonic polyhedra (tetrahedron, hexahedron,\n');
        fprintf('octahedron, dodecahedron and icosahedron) OR a geodesic sphere by\n');
        fprintf('progressive subdivision of the faces of the polyhedra with triangular\n');
        fprintf('faces (tetrahedron, octahedron and icosahedron). Icosahedron is the\n');
        fprintf('recommended choice for a geodesic sphere (icosphere).\n');
        fprintf('\n');
        fprintf('Usage:\n');
        fprintf('platonic <fname.obj> <pname> <meas> <mval> [trans] [rnd]\n');
        fprintf(' fname : File to be created, in OBJ format.\n');
        fprintf(' pname : Platonic polyhedron to be created. Choose one of the following:\n');
        fprintf('         ''tetra'', ''hexa'', ''octa'', ''dode'' or ''ico''.\n');
        fprintf(' meas  : Measurement that have its value defined. Choose one of the following:\n');
        fprintf('         ''e'' : Edge length                   ''v'' : Volume\n');
        fprintf('         ''af'': Area of the face              ''cr'': Circumradius\n');
        fprintf('         ''at'': Total area                    ''ir'': Inradius\n');
        fprintf('         Alternatively, use ''sph'' to subdivide each triangular face ''mval''\n');
        fprintf('         times and project the vertices to the surface of a sphere of radius 1.\n');
        fprintf(' mval  : Value defined for the measurement (''meas'') or number of iteractions\n');
        fprintf('         for subdivision of the faces.\n');
        fprintf(' trans : Optional. Once the polyhedron/sphere is constructed with the parameters\n');
        fprintf('         given by meas and mval, apply a transformation to position it in the 3D\n');
        fprintf('         space and possibly scale it. TRANS can be a a singleton [x] specifying a\n');
        fprintf('         scaling factor, a triplet [x y z] specifying the new center, or a\n');
        fprintf('         full 4x4 affine matrix defining translation, rotation, scaling and shear.\n');
        fprintf('         Should be entered between single quotes, e.g. ''[2 4 -1]''.\n');
        fprintf(' rnd   : Optional. Perturb the locations of the vertices if set as true.\n');
        fprintf('\n');
        fprintf('Important: Use placemakers for non-given arguments if another is placed later.\n');
        fprintf('\n');
        fprintf('_____________________________________\n');
        fprintf('Anderson M. Winkler\n');
        fprintf('Yale University / Institute of Living\n');
        fprintf('Jan/2011\n');
        return;
    end
end

% Defaults
d.fname = '';
d.pname = '';
d.meas  = 'cr';
d.m     = 1;
d.T     = '';
d.rand  = 'false';
d.rad   = 1;

% Check number of arguments
nargin = numel(varargin); % Redundant in MATLAB, but fixes an issue with OCTAVE compatibility
if exist('argv','var') && (nargin < 2 || nargin > 5), % POSIX compatibility
    error('Incorrect number of arguments.\n')
end

% Receive inputs
fields = fieldnames(d);
for a = 1:nargin,
    d.(fields{a}) = varargin{a};
end

% For simplicity, remove from the struct
d.meas = lower(d.meas);
if isnumeric(d.m),
    m = d.m;
else
    m = str2num(d.m);
end
if isnumeric(d.T),
    T = d.T;
else
    T = str2num(d.T);
end
if ischar(d.rand),
    d.rand = str2num(d.rand);
end
newr = d.rad;

% Get the correct polyhedra
switch lower(d.pname),

    case 'tetra', % TETRAHEDRON
        % Vertex coordinates for edge = 2*sqrt(2)
        vtx = [
            1 1 1;    % 1
            -1 1 -1;  % 2
            1 -1 -1;  % 3
            -1 -1 1]; % 4
        % Face indices
        fac = [
            1 3 2;
            2 3 4;
            1 4 3;
            1 2 4];
        % Make edge = 1
        vtx = vtx/(2*sqrt(2));
        % Normalise according to measurement
        switch d.meas,
            case 'e' , vtx = vtx * m;
            case 'af', vtx = vtx * sqrt(4*m/sqrt(3));
            case 'at', vtx = vtx * sqrt(m/sqrt(3));
            case 'v' , vtx = vtx * (12*m/sqrt(2))^(1/3);
            case 'cr', vtx = vtx * m*sqrt(8/3);
            case 'ir', vtx = vtx * m*sqrt(24);
            case 'sph', [vtx,fac] = subdivtri(vtx,fac,m,newr);
            otherwise, error('Measurement "%s" not available for "%s"\n',d.meas,d.pname);
        end

    case 'hexa', % HEXAHEDRON
        % Vertex coordinates for edge = 2
        vtx = [
            1 1 -1;    % 1
            1 -1 -1;   % 2
            -1 -1 -1;  % 3
            -1 1 -1;   % 4
            1 1 1;     % 5
            1 -1 1;    % 6
            -1 -1 1;   % 7
            -1 1 1];   % 8
        % Face indices
        fac = [
            1 2 3 4;
            5 8 7 6;
            1 5 6 2;
            2 6 7 3;
            3 7 8 4;
            5 1 4 8];
        % Make edge = 1
        vtx = vtx/2;
        % Normalise according to measurement
        switch d.meas,
            case 'e' , vtx = vtx * m;
            case 'af', vtx = vtx * sqrt(m);
            case 'at', vtx = vtx * sqrt(m/6);
            case 'v' , vtx = vtx * m^(1/3);
            case 'cr', vtx = vtx * 2*m/sqrt(3);
            case 'ir', vtx = vtx * 2*m;
            case 'sph', error('Face subdivision is available only for polyhedra\nwith triangular faces ("tetra", "octa" and "ico").\n');
            otherwise, error('Measurement "%s" not available for "%s"\n',d.meas,d.pname);
        end

    case 'octa', % OCTAHEDRON
        % Vertex coordinates for edge = sqrt(2)
        vtx = [
            1 0 0;    % 1
            0 1 0;    % 2
            0 0 1;    % 3
            -1 0 0;   % 4
            0 -1 0;   % 5
            0 0 -1];  % 6
        % Face indices
        fac = [
            1 2 3;
            2 4 3;
            4 5 3;
            5 1 3;
            2 1 6;
            4 2 6;
            5 4 6;
            1 5 6];
        % Make edge = 1
        vtx = vtx/sqrt(2);
        % Normalise according to measurement
        switch d.meas,
            case 'e' , vtx = vtx * m;
            case 'af', vtx = vtx * sqrt(4*m/sqrt(3));
            case 'at', vtx = vtx * sqrt(m/(2*sqrt(3)));
            case 'v' , vtx = vtx * (3*m/sqrt(2))^(1/3);
            case 'cr', vtx = vtx * 2*m/sqrt(2);
            case 'ir', vtx = vtx * 6*m/sqrt(6);
            case 'sph', [vtx,fac] = subdivtri(vtx,fac,m,newr);
            otherwise, error('Measurement "%s" not available for "%s"\n',d.meas,d.pname);
        end

    case 'dode', % DODECAHEDRON
        % Vertex coordinates for edge = 2/g
        g = (1+sqrt(5))/2; % Golden ratio (~1.618)
        vtx = [
            1/g 0 g;    % 1
            -1/g 0 g;   % 2
            1/g 0 -g;   % 3
            -1/g 0 -g;  % 4
            0 g -1/g;   % 5
            0 g 1/g;    % 6
            0 -g -1/g;  % 7
            0 -g 1/g;   % 8
            g 1/g 0;    % 9
            g -1/g 0;   % 10
            -g 1/g 0;   % 11
            -g -1/g 0;  % 12
            1 1 1;      % 13
            -1 1 1;     % 14
            1 -1 1;     % 15
            1 1 -1;     % 16
            1 -1 -1;    % 17
            -1 1 -1;    % 18
            -1 -1 1;    % 19
            -1 -1 -1];  % 20
        % Face indices
        fac = [
            13 6 14 2 1;
            19 8 15 1 2;
            17 7 20 4 3;
            18 5 16 3 4;
            5 6 13 9 16;
            6 5 18 11 14;
            7 8 19 12 20;
            8 7 17 10 15;
            13 1 15 10 9;
            17 3 16 9 10;
            18 4 20 12 11;
            19 2 14 11 12];
        % Make edge = 1
        vtx = vtx*g/2;
        % Normalise according to measurement
        switch d.meas,
            case 'e' , vtx = vtx * m;
            case 'af', vtx = vtx * sqrt(4*m/sqrt(25+10*sqrt(5)));
            case 'at', vtx = vtx * sqrt(m/(3*sqrt(25+10*sqrt(5))));
            case 'v' , vtx = vtx * (4*m/(15+7*sqrt(5)))^(1/3);
            case 'cr', vtx = vtx * 4*m/(sqrt(15)+sqrt(3));
            case 'ir', vtx = vtx * 20*m/sqrt(250+110*sqrt(5));
            case 'sph', error('Face subdivision is available only for polyhedra\nwith triangular faces ("tetra", "octa" and "ico").\n');
            otherwise, error('Measurement "%s" not available for "%s"\n',d.meas,d.pname);
        end

    case 'ico', % ICOSAHEDRON
        % Vertex coordinates for edge = 2
        g = (1+sqrt(5))/2; % Golden ratio (~1.618)
        vtx = [
            0 1 g;    % 1
            0 -1 g;   % 2
            0 1 -g;   % 3
            0 -1 -g;  % 4
            1 g 0;    % 5
            -1 g 0;   % 6
            1 -g 0;   % 7
            -1 -g 0;  % 8
            g 0 1;    % 9
            g 0 -1;   % 10
            -g 0 1;   % 11
            -g 0 -1]; % 12
        % Face indices
        fac = [
            1 2 9;
            1 11 2;
            3 10 4;
            3 4 12;
            2 8 7;
            4 7 8;
            6 1 5;
            3 6 5;
            7 10 9;
            9 10 5;
            8 11 12;
            6 12 11;
            2 7 9;
            1 9 5;
            11 8 2;
            11 1 6;
            7 4 10;
            8 12 4;
            3 5 10
            3 12 6];
        % Make edge = 1
        vtx = vtx/2;
        % Normalise according to measurement
        switch d.meas,
            case 'e' , vtx = vtx * m;
            case 'af', vtx = vtx * sqrt(4*m/sqrt(3));
            case 'at', vtx = vtx * sqrt(m/(5*sqrt(3)));
            case 'v' , vtx = vtx * (12*m/(5*(3+sqrt(5))))^(1/3);
            case 'cr', vtx = vtx * 4*m/sqrt(10+2*sqrt(5));
            case 'ir', vtx = vtx * 12*m/sqrt(42+18*sqrt(5));
            case 'sph', [vtx,fac] = subdivtri(vtx,fac,m,newr);
            otherwise, error('Measurement "%s" not available for "%s"\n',d.meas,d.pname);
        end
    otherwise
        error('Polyhedron ''%s'' is not available. Use ''tetra'', ''hexa'',\n''octa'', ''dode'', ''ico'' instead\n',d.pname);
end

% Perturb vertex positions
if d.rand,

    % Get current radius (temporary)
    [~,~,tmprad] = cart2sph(vtx(:,1),vtx(:,2),vtx(:,3));
    tmprad = mean(tmprad);

    % Get the edge length
    tmpvtx = [vtx(fac(1,1:2),1) vtx(fac(1,1:2),2) vtx(fac(1,1:2),3)];
    tmpedg = norm(tmpvtx(1,:)-tmpvtx(2,:));

    % Perturb coordinates
    pert = rand(size(vtx))-.5;
    wild = .5;                     % Std dev >wild will be discarded below (if w/ randn)
    pert(abs(pert)>wild) = 0;      % Discard wild perturbations
    pert = pert.*tmpedg./(3*wild); % Scale to 1/3 of the edge length
    vtx = vtx + pert;              % Add the perturbations in cartesian coordinates
    Svtx = zeros(size(vtx));       % Spherical coordinates
    [Svtx(:,1),Svtx(:,2),Svtx(:,3)] = ...
        cart2sph(vtx(:,1),vtx(:,2),vtx(:,3));
    [vtx(:,1),vtx(:,2),vtx(:,3)] = ...
        sph2cart(Svtx(:,1),Svtx(:,2),tmprad*ones(size(vtx,1),1));
end

% Change the center or apply a full affine matrix (4x4)
if numel(T) == 1,                     % Scale only
    vtx = vtx * T;
elseif numel(T) == 3,                 % Translation only
    T = reshape(T,1,3);
    vtx = vtx + repmat(T,[size(vtx,1) 1]);
elseif all(size(T) == [4 4]) && ...   % Full affine
        all(T(4,:) == [0 0 0 1]),
    vtx = [vtx ones(size(vtx,1),1)] * T';
    vtx = vtx(:,1:3);
elseif isempty(T),                    % Nothing
else
    error('Invalid transformation.\n')
end

% Save as OBJ
fid = fopen(d.fname,'w');
fprintf(fid,'v %.10f %.10f %.10f\n',vtx');
if strcmp(d.pname,'hexa'),
    fprintf(fid,'f %d %d %d %d\n',fac');
elseif strcmp(d.pname,'dode'),
    fprintf(fid,'f %d %d %d %d %d\n',fac');
else
    fprintf(fid,'f %d %d %d\n',fac');
end
fclose(fid);
