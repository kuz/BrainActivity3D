% #!/usr/bin/octave -q
function smoothdpx(varargin)
% Smooth data per face (DPF) or data per vertex (DPV) with a Gaussian kernel
% of a specified width. The user must supply a spherical reference surface.
%
% Usage:
% smoothdpx(dpx1file,srffile,dpx2file,fwhm)
%
% dpx1file  : Input DPV/DPF file, which values will be spatially smoothed.
% srffile   : Surface reference file.
% dpx2file  : Output DPV/DPF file, with smoothed data.
% fwhm      : Full-Width at Half Maximum of the Gaussian filter.
%
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Aug/2011
% http://brainder.org

try
    % Get the inputs
    varargin = argv();

    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);

    % Print usage if no inputs are given
    if isempty(varargin) || strcmp(varargin{1},'-q'),

        fprintf('Smooth data per face (DPF) or data per vertex (DPV) with a Gaussian kernel\n');
        fprintf('of a specified width. The user must supply a spherical reference surface.\n');
        fprintf('\n');
        fprintf('Usage:\n');
        fprintf('smoothdpx <dpx1file> <srffile> <dpx2file> <fwhm>\n');
        fprintf('\n');
        fprintf('dpx1file  : Input DPV/DPF file, which values will be spatially smoothed.\n');
        fprintf('srffile   : Surface reference file.\n');
        fprintf('dpx2file  : Output DPV/DPF file, with smoothed data.\n');
        fprintf('fwhm      : Full-Width at Half Maximum of the Gaussian filter.\n');
        fprintf('\n');
        fprintf('_____________________________________\n');
        fprintf('Anderson M. Winkler\n');
        fprintf('Yale University / Institute of Living\n');
        fprintf('Aug/2011\n');
        fprintf('http://brainder.org\n');
        return;
    end
end

% Get the inputs
crv1file = varargin{1};
srffile  = varargin{2};
crv2file = varargin{3};
fwhm     = varargin{4};
if ischar(fwhm), fwhm = eval(fwhm); end

% Read 'curvature' and reference surface (sphere)
[crv1,crd1,idx1] = dpxread(crv1file);
[vtx1,fac1] = srfread(srffile);
nX = numel(crv1);   % Number of datapoints to smooth
nV = size(vtx1,1);  % Number of vertices
nF = size(fac1,1);  % Number of faces

% See if facewise or vertexwise data
if nX == nF,
    fprintf('Smoothing facewise data, FWHM=%g\n',fwhm);
    facvtx = [vtx1(fac1(:,1),:) vtx1(fac1(:,2),:) vtx1(fac1(:,3),:)];
    vtx1 = [mean(facvtx(:,[1 4 7]),2) ...  % Barycenter
        mean(facvtx(:,[2 5 8]),2) mean(facvtx(:,[3 6 9]),2)];
elseif nX == nV,
    fprintf('Smoothing vertexwise data, FWHM=%g\n',fwhm);
else
    error('Data to smooth does not match surface geometry');
end

% Get an approx to the sphere radius
[ignore,ignore,R1] = cart2sph(vtx1(:,1),vtx1(:,2),vtx1(:,3));
R = mean(R1);       % Radius of sphere

% Precalculate constants for the kernel
sigma = fwhm/sqrt(8*log(2));
cte1  = 1/sigma/sqrt(2*pi);
cte2  = -1/(2*sigma^2);

% Where to store result
crv2 = zeros(size(crv1));

% Loop over datapoints (vertices or centers of faces)
for v = 1:nX,

    % Geodesic distance between current vertex and all other vertices
    vtx = repmat(vtx1(v,:),[nX 1]);
    G   = gdist(vtx,vtx1,R);
    idx = G < (3*fwhm);

    % Solve the filter for the vertex locations (distances)
    K   = cte1*exp(cte2*G(idx).^2);
    K   = K/sum(K);

    % Weight
    crv2(v) = sum(crv1(idx).*K);

end

% If the filter is huge, there may be tiny imaginary parts.
% Take the real part only
crv2 = real(crv2);

% Save result
dpxwrite(crv2file,crv2,crd1,idx1);
