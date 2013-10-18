% #!/usr/bin/octave -q
function srf2srf(varargin)
% Resample an ASCII DPV or DPF file with a geometry given by a source surface
% file to another DPV or DPF file using the geometry of a target surface.
% Different interpolation methods are available.
% 
% Usage:
% - For facewise data, usage is:
% srf2srf('areal',srf1file,srf2file,olptable,dpf1file,dpf2file,srfRfile,faclist)
% 
% - For vertexwise data, usage is:
% srf2srf(method,srf1file,srf2file,dpf1file,dpf2file,srfRfile)
% 
% Arguments:
% - method   : Choose one from 'areal', 'distributive', 'barycentric'
%              or 'nearest'.
% - srf1file : Source surface file. It has to be a sphere.
% - srf2file : Target surface file. It has to be a sphere.
% - overlaps : Table with the face indices and overlapping areas. This is
%              applies only to, and is a compulsory argument for, 'areal'.
% - dpx1file : Source DPV/DPF (aka curvature) file. For the
%             'barycentric', 'distributive' and 'nearest', it is a DPV
%              file. For 'areal', it is a DPF file.
% - dpx2file : Target DPV/DPF file to be created. For the 'barycentric',
%              'distributive' and 'nearest', it is a DPV file. For 'areal' it
%              is a DPF file. The geometry information (vertex coordinates or
%              face indices) is obtained by default from the target surface file.
%              This can be overriden by specifying a reference surface.
% - srfRfile : Optional. Reference surface, used only to obtain vertex
%              coordinates or face indices for the target DPV/DPF file.
%              It can be any surface with same number of vertices or faces
%              as the target surface.
% - faclist  : Optional. Run the areal interpolation only for the target faces
%              which indices are listed in the faclist file. This is a text file
%              containing one face index per line.
% 
% For facewise data, dpf1file, dpf2file, srfRfile and faclist are OPTIONAL.
% For vertexise data, only srfRfile is OPTIONAL.
% 
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jul/2011
% http://brainder.org

% Start assuming this is MATLAB; change below
isoct = false;

% OCTAVE stuff, with TRY to ensure MATLAB compatibility
try %#ok
    % Get the inputs
    varargin = argv();

    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);

    % Print usage if no inputs are given
    if isempty(varargin) || strcmp(varargin{1},'-q'),

        fprintf('Resample an ASCII DPV or DPF file with a geometry given by a source surface\n');
        fprintf('file to another DPV or DPF file using the geometry of a target surface.\n');
        fprintf('Different interpolation methods are available.\n');
        fprintf('\n');
        fprintf('Usage:\n');
        fprintf('- For facewise data, usage is:\n');
        fprintf('srf2srf(''areal'',srf1file,srf2file,olptable,dpf1file,dpf2file,srfRfile,faclist)\n');
        fprintf('\n');
        fprintf('- For vertexwise data, usage is:\n');
        fprintf('srf2srf(method,srf1file,srf2file,dpf1file,dpf2file,srfRfile)\n');
        fprintf('\n');
        fprintf('Arguments:\n');
        fprintf('- method   : Choose one from ''areal'', ''distributive'', ''barycentric''\n');
        fprintf('            or ''nearest''.\n');
        fprintf('- srf1file : Source surface file. It has to be a sphere.\n');
        fprintf('- srf2file : Target surface file. It has to be a sphere.\n');
        fprintf('- overlaps : Table with the face indices and overlapping areas. This is\n');
        fprintf('            applies only to, and is a compulsory argument for, ''areal''.\n');
        fprintf('- dpx1file : Source DPV/DPF (aka curvature) file. For the\n');
        fprintf('            ''barycentric'', ''distributive'' and ''nearest'', it is a DPV\n');
        fprintf('            file. For ''areal'', it is a DPF file.\n');
        fprintf('- dpx2file : Target DPV/DPF file to be created. For the ''barycentric'',\n');
        fprintf('            ''distributive'' and ''nearest'', it is a DPV file. For ''areal'' it\n');
        fprintf('            is a DPF file. The geometry information (vertex coordinates or\n');
        fprintf('            face indices) is obtained by default from the target surface file.\n');
        fprintf('            This can be overriden by specifying a reference surface.\n');
        fprintf('- srfRfile : Optional. Reference surface, used only to obtain vertex\n');
        fprintf('            coordinates or face indices for the target DPV/DPF file.\n');
        fprintf('            It can be any surface with same number of vertices or faces\n');
        fprintf('            as the target surface.\n');
        fprintf('- faclist  : Optional. Run the areal interpolation only for the target faces\n');
        fprintf('            which indices are listed in the faclist file. This is a text file\n');
        fprintf('            containing one face index per line.\n');
        fprintf('\n');
        fprintf('For facewise data, dpf1file, dpf2file, srfRfile and faclist are OPTIONAL.\n');
        fprintf('For vertexise data, only srfRfile is OPTIONAL.\n');
        fprintf('\n');
        fprintf('_____________________________________\n');
        fprintf('Anderson M. Winkler\n');
        fprintf('Yale University / Institute of Living\n');
        fprintf('Jul/2011\n');
        fprintf('http://brainder.org\n');
        return;
    end
    
    % If got here, this is certainly OCTAVE
    isoct = true;
end

% Defaults
d.marg =  0.05;  % Default margin

% Check number and accept the arguments
d.meth = varargin{1};
if strcmpi(d.meth,'areal'),
    expnarg = [4 8]; % Expected number of arguments
    fields = {'fsrf1','fsrf2','ovtab','fcrv1','fcrv2','fsrfR','flist'};
else
    expnarg = [5 6]; % Expected number of arguments
    fields = {'fsrf1','fsrf2','fcrv1','fcrv2','fsrfR'};
end
nargin = numel(varargin); % This is redundant in MATLAB, but fixes a certain behaviour in OCTAVE
if nargin < expnarg(1) || nargin > expnarg(2),
    error('Invalid number of arguments');
end
for a = 2:nargin, % Start from 2, as d.meth was already taken
    d.(fields{a-1}) = varargin{a};
end

% Print some info
fprintf('Using %s interpolation.\n',d.meth);
fprintf('Source surface: %s\n',d.fsrf1);
fprintf('Target surface: %s\n',d.fsrf2);

% Load the source surface (srf1)
[vtx1,fac1] = srfread(d.fsrf1);
nV1 = size(vtx1,1);
nF1 = size(fac1,1);

% Load the target surface (srf2)
[vtx2,fac2] = srfread(d.fsrf2);
nV2 = size(vtx2,1);
nF2 = size(fac2,1);

% Load the reference surface (srfr)
if isfield(d,'fsrfR') && ~isempty(d.fsrfR)
    [vtxr,facr] = srfread(d.fsrfR);
else
    vtxr = vtx2;
    facr = fac2;
end

% Load the source curvature (crv1).
if isfield(d,'fcrv1') && ~isempty(d.fcrv1),
    crv1 = dpxread(d.fcrv1);
elseif strcmpi(d.meth,'areal'),
    crv1 = zeros(nF1,1);
else
    error('You must specify a source DPV file to use vertexwise interpolation.')
end

% If not areal and no target DPV was specified, give the error now, rather than at the end
if ~strcmpi(d.meth,'areal') && (~isfield(d,'fcrv2') || isempty(d.fcrv2)),
    error('You must specify a target DPV file to use vertexwise interpolation.')
end

% Load the list of faces on the target (only these will be interpolated)
if isfield(d,'flist') && ~isempty(d.flist),
    fid = fopen(d.flist,'r');
    flist2 = fscanf(fid,'%g',Inf);
    fclose(fid);
    flist2 = flist2';
elseif strcmpi(d.meth,'areal'),
    flist2 = 1:nF2;
end

% Switch methods
switch lower(d.meth),

    case 'areal'

        % Create the file to store the table with the overlaps. It saves
        % time to write immediately to the file, rather than keep a
        % variable growing in the memory to be saved later.
        % For code simplicity, it's now a compulsory argument for areal.
        % Fix this later...
        fidolp = fopen(d.ovtab,'w');

        % Where the result is going to be stored
        crv2 = zeros(nF2,1);

        % =====[ PART 1 ]=====
        % Check in which source face the target vertices lie in.
        fprintf('Running Part 1\n');

        % Vertices' coords per face
        facvtx1 = [vtx1(fac1(:,1),:) vtx1(fac1(:,2),:) vtx1(fac1(:,3),:)];

        % Compute quickly the area per face of the source, to be used later
        tmp = facvtx1(:,1:6) - [facvtx1(:,7:9) facvtx1(:,7:9)];  % Place 3rd vtx at origin
        tmp = cross(tmp(:,1:3),tmp(:,4:6),2);                    % Cross product
        apf1 = sqrt(sum(tmp.^2,2))./2;                           % Half of the norm

        % For each face, it's necessary to have a point of reference close enough to
        % it, preferably inside the face. This point will be used later down as the
        % reference to rotate the coordinate system and simplify the actual interpolation.
        % The easiest point is just the barycenter.
        cbary = [mean(facvtx1(:,[1 4 7]),2) ... % Cartesian coordinates
            mean(facvtx1(:,[2 5 8]),2) mean(facvtx1(:,[3 6 9]),2)];
        sbary = zeros(nF1,3);
        [sbary(:,1),sbary(:,2),sbary(:,3)] = ... % Spherical coordinates
            cart2sph(cbary(:,1),cbary(:,2),cbary(:,3));

        % Mean radius of the source, to be used later
        meanR1 = mean(sbary(:,3));

        % Pre-calculated sines and cosines of azimuth (A) and elevation (E)
        sinA = sin(sbary(:,1));
        sinE = sin(sbary(:,2));
        cosA = cos(sbary(:,1));
        cosE = cos(sbary(:,2));

        % Pre-calculated rotation matrices, one per row. To make them full 3x3,
        % use reshape(rotM(f,:),[3 3]). These matrices rotate the coordinate
        % system to the barycenter of the face (i.e., they "unrotate" the face).
        % The rotation considers only azimuth (around Z) and elevation (around Y
        % once azimuth has been discounted). There is no reason to rotate around X,
        % therefore, no need for a full implementation of the Euler/Rodrigues
        % angles, neither for quaternions. In fact, the azimuth isn't strictly
        % necessary either, but it has to be zero so that elevation becomes
        % around Y, not around any other random axis.
        %
        % RotM as computed below is RotZ*RotY (in this order), where:
        % RotZ = [ cos(Az) -sin(Az)     0  ;
        %          sin(Az)  cos(Az)     0  ;
        %             0        0        1  ]
        % RotY = [ cos(El)     0     -sin(El) ;
        %             0        1         0    ;
        %          sin(El)     0      cos(El) ]
        rotM = [cosA.*cosE sinA.*cosE sinE -sinA cosA zeros(nF1,1) -cosA.*sinE -sinA.*sinE cosE];

        % Pre-calculated min and max for each face and bounding box
        minF = [min(facvtx1(:,[1 4 7]),[],2) ...
            min(facvtx1(:,[2 5 8]),[],2) min(facvtx1(:,[3 6 9]),[],2)];
        maxF = [max(facvtx1(:,[1 4 7]),[],2) ...
            max(facvtx1(:,[2 5 8]),[],2) max(facvtx1(:,[3 6 9]),[],2)];
        b = repmat(max((maxF-minF),[],2),[1 3]) * d.marg;  % <= marg enters here
        minF = minF - b;
        maxF = maxF + b;

        % Initialize a variable to register in which face on the 1st
        % surface a vertex from the 2nd surface lies in
        vtx2onfac1 = zeros(nV2,1);

        % List for the faces that are attached to the vertices on source
        fpvlist = cell(nV1,1); % will be filled inside the for-loop below

        % For each source face
        for f = 1:nF1,

            % Face vertices
            Fvtx = vtx1(fac1(f,:),:);

            % Candidate vertices within the bounding box
            Cidx = all(vtx2 >= repmat(minF(f,:),[nV2 1]) & ...
                vtx2 <= repmat(maxF(f,:),[nV2 1]),2);
            Cvtx = vtx2(Cidx,:);
            Cidxi = find(Cidx);

            % Rotate the face vertices and candidate vertices to near [r,0,0]. This
            % allows projecting them to the surface sphere and collapse the radius
            % dimension, allowing the interpolation to run in 2D, which is faster, and
            % avoiding problems with angle wrapping near the poles of the original spheres.
            % Also, it may possibly reduce distortions near the poles.
            % A further advantage is that collapsing one dimention (here
            % it is the radius) allow the candidate vertices to be 'coplanar' with the
            % face being tested. The computational burden should have been alleviated by
            % pre-computing the rotation matrix before this for-loop. Even if it were not
            % alleviated, the benefits listed above should compensate
            % performance concerns.
            % In the Avtx below, the first 3 rows are the face vertices in source,
            % the remaining the candidate vertices in the target sphere:
            Avtx = [Fvtx; Cvtx] * reshape(rotM(f,:),[3 3]); % This is still Cartesian

            % The tests to see if the vertex is inside the face and
            % later to test for intersection between edges cannot be done
            % on the simple plate carrée projection, since lines are
            % loxodromic trajectories and do not correspond to true, great
            % circle distances. The solution, particularly important to
            % compute the intersections, is to use the azimuthal gnomonic
            % projection. It is very simple to compute, just calculate the
            % trigonometric tangents after the rotation of the Cartesian
            % coordinates.
            Gvtx = ones(size(Avtx,1),3);       % The 3rd col will remain full of ones
            Gvtx(:,1) = Avtx(:,2)./Avtx(:,1);  % Tangent of the angle on the XY plane
            Gvtx(:,2) = Avtx(:,3)./Avtx(:,1);  % Tangent of the angle on the XZ plane
            T = Gvtx(1:3,:);                   % Face coords for the test below

            % For every candidate vertex, test if inside the triangle
            for v = 1:numel(Cidxi),

                % Test if the point is inside the face and register to the list
                tA = T; tA(1,:) = Gvtx(v+3,:);  % Subtriangle A
                tB = T; tB(2,:) = Gvtx(v+3,:);  % Subtriangle B
                tC = T; tC(3,:) = Gvtx(v+3,:);  % Subtriangle C
                if single(det(T)) == ...        % Single to avoid errors due to precision
                        single(sum(abs([det(tA) det(tB) det(tC)])));
                    vtx2onfac1(Cidxi(v)) = f;
                end
            end

            % Still in the same loop, do the unrelated task of finding the
            % source faces that meet at each source vertex. For speed, this
            % should have been implemented with repmat, outside the
            % for-loop. However, the large nV1 and nF1 make memory
            % requirements prohibitive.
            fpvlist{fac1(f,1)} = [fpvlist{fac1(f,1)} f];
            fpvlist{fac1(f,2)} = [fpvlist{fac1(f,2)} f];
            fpvlist{fac1(f,3)} = [fpvlist{fac1(f,3)} f];
        end

        % =====[ PART 2 ]=====
        % Do the actual interpolation
        fprintf('Running Part 2\n');

        % This gives the 3 face numbers on source that contain the 3 vertices of
        % the target face. There might be repetitions, but it doesn't matter.
        fac1withvtx2 = [vtx2onfac1(fac2(:,1)) vtx2onfac1(fac2(:,2)) vtx2onfac1(fac2(:,3))];

        % These are the numbers of 9 "seed" vertices on source. Every face attached to
        % them are candidate faces and will be used for the bounding box
        vtx1seed = [fac1(fac1withvtx2(:,1),:) fac1(fac1withvtx2(:,2),:) fac1(fac1withvtx2(:,3),:)];

        % Vertices' coords per target face
        facvtx2 = [vtx2(fac2(:,1),:) vtx2(fac2(:,2),:) vtx2(fac2(:,3),:)];

        % Compute quickly the area per face of the target (all faces)
        tmp  = facvtx2(:,1:6) - [facvtx2(:,7:9) facvtx2(:,7:9)];  % Place 3rd vtx at origin
        tmp  = cross(tmp(:,1:3),tmp(:,4:6),2);                    % Cross product
        apf2 = sqrt(sum(tmp.^2,2))./2;                            % Half of the norm

        % Barycenter for each target face
        cbary = [mean(facvtx2(:,[1 4 7]),2)  ...  % Cartesian coordinates
            mean(facvtx2(:,[2 5 8]),2) mean(facvtx2(:,[3 6 9]),2)];
        sbary = zeros(nF2,3);
        [sbary(:,1),sbary(:,2),sbary(:,3)] = ...  % Spherical coordinates
            cart2sph(cbary(:,1),cbary(:,2),cbary(:,3));

        % Mean radius of the target
        meanR2 = mean(sbary(:,3));

        % Scale the area per vertex of the source to match the target
        apf1 = apf1.*((meanR2/meanR1)^2);

        % Pre-calculated sines and cosines of azimuth (A) and elevation (E)
        sinA = sin(sbary(:,1));
        sinE = sin(sbary(:,2));
        cosA = cos(sbary(:,1));
        cosE = cos(sbary(:,2));

        % Precalculated rotation matrix, now for the target
        rotM = [cosA.*cosE sinA.*cosE sinE -sinA cosA zeros(nF2,1) -cosA.*sinE -sinA.*sinE cosE];

        % Clear some large unused vars to free up some memory
        clear sinA sinE cosA cosE sbary cbary facvtx1 facvtx2 b maxF minF tmp;

        % Include a random angle around X, so that it prevents an issue with
        % perfectly horizontal edges, which cause rounding errors and true
        % edge intersections to be missed some lines below
        rndangX = rand(1)*pi;
        sinX = sin(rndangX);
        cosX = cos(rndangX);
        rotM = [ rotM(:,1:3) ...
            rotM(:,4)*cosX+rotM(:,7)*sinX rotM(:,5)*cosX+rotM(:,8)*sinX rotM(:,6)*cosX+rotM(:,9)*sinX ...
            rotM(:,7)*cosX-rotM(:,4)*sinX rotM(:,8)*cosX-rotM(:,5)*sinX rotM(:,9)*cosX-rotM(:,6)*sinX ];

        % Indices for start and end vertices for each edge, to be
        % used inside the for-loop below
        strp = [1 2 3];
        endp = [2 3 1];

        % For every target face
        for f = flist2;

            % Target face vertices
            vidx = fac2(f,:);
            Fvtx = vtx2(vidx,:);

            % Check if the vertices of the target face are all in the same face on
            % source. If yes, this saves a lot of time...
            cf = unique(vtx2onfac1(vidx));  % cf here ranges between 1 and nF1

            if numel(cf) == 1,
                % The attribute to be assigned to the target face is
                % then the attribute of the source face times the
                % proportion between the area in the target and the area in
                % the source.
                crv2(f) = crv1(cf) * apf2(f)/apf1(cf);

                % Write the table with the overlaps to the disk
                fprintf(fidolp,'%u %u %g %g %g\n',cf,f,apf2(f),apf1(cf),apf2(f));

                % Use this opportunity to show it's not frozen and print some
                % feedback in the screen
                fprintf('Current face: %g\n',f);

            else
                % Get the extreme coordinates (lower-left and upper-right corners)
                fac1seed = unique([fpvlist{vtx1seed(f,:)}]);
                vtx1sel = [vtx1(fac1(fac1seed,1),:) vtx1(fac1(fac1seed,2),:) vtx1(fac1(fac1seed,3),:)];
                vtx1sel = reshape(vtx1sel',[3 numel(vtx1sel)/3])';
                llcnr = min(vtx1sel);   urcnr = max(vtx1sel);

                % Expand a bit to get extra vertices
                b = (urcnr-llcnr) * d.marg * 4;  % margin has to be larger to include faces
                llcnr = llcnr - b;   urcnr = urcnr + b;

                % Select candidate vertices within the bounding box. This
                % should include the same vertices that define the "seed"
                % faces, plus others that may lie amidst them.
                Cidx = all(vtx1 >= repmat(llcnr,[nV1 1]) & ...
                    vtx1 <= repmat(urcnr,[nV1 1]),2);
                Cvtx = vtx1(Cidx,:);

                % Though slower than logical indexing, it'll be necessary below...
                Cidxi = find(Cidx);

                % Get the faces that are entirely within the bounding box.
                % Ideally, the next test should be something like:
                %    somevar = all(repmat(Cidxi,[1 nF1 3]) == ...
                %                repmat(permute(fac1,[3 1 2]),[numel(Cidxi) 1 1]),3);
                % However, this may easily exceed memory limits. To avoid, the
                % for-loop below should do the trick...
                o = ones(size(fac1)); Cfac = false(size(fac1));
                for cv = 1:numel(Cidxi),   % For each candidate vertex
                    Cfac = or(Cfac,(Cidxi(cv)*o == fac1));
                end
                Cfac = all(Cfac,2);
                Cfaci = find(Cfac);

                % Number of candidate vertices and faces
                nVc = numel(Cidxi);
                nFc = numel(Cfaci);

                % Logical matrix of in which candidate face (source) the
                % current target face vertices are. This will be used much
                % later down the code
                vtx_f_in_cf = repmat(Cfaci,[1 3]) == repmat(vtx2onfac1(fac2(f,:))',[nFc 1]);

                % Re-index Cfac to use the vertex indices of the current set
                tmp1 = repmat(fac1(Cfaci,:),[1 1 nVc]);
                tmp2 = repmat(permute(Cidxi,[3 2 1]),[nFc 3 1]);
                tmp3 = ( tmp1 == tmp2 ) .* ...
                    repmat(permute((1:nVc),[1 3 2]),[nFc 3 1]);
                Cfac0 = sum(tmp3,3);

                % Rotate the face vertices and candidate vertices to near [r,0,0].
                rotMf = reshape(rotM(f,:),[3 3]);
                Ftmp = Fvtx * rotMf;  % These coordinates are still Cartesian, with X~100
                Ctmp = Cvtx * rotMf;

                % Convert to gnomonic
                Fvtx0 = zeros(size(Fvtx,1),2);
                Fvtx0(:,1) = Ftmp(:,2)./Ftmp(:,1);  % Tangent of the angle on the XY plane
                Fvtx0(:,2) = Ftmp(:,3)./Ftmp(:,1);  % Tangent of the angle on the XZ plane
                Cvtx0 = zeros(size(Cvtx,1),2);
                Cvtx0(:,1) = Ctmp(:,2)./Ctmp(:,1);  % Tangent of the angle on the XY plane
                Cvtx0(:,2) = Ctmp(:,3)./Ctmp(:,1);  % Tangent of the angle on the XZ plane

                % Vertices of the edges of the current face, in a row
                % vector size 3x4 = [xA yA xB yB; xB yB xC yC; xC yC xA yA]
                Fedgvtx0 = [ Fvtx0(strp,1:2) Fvtx0(endp,1:2) ];

                % Subtract 1st point from the 2nd, so that the edge is shifted with
                % its 1st vertex at the origin. 'E' is 3x2 matrix, with the 2nd
                % point only. 1st point is [0 0]
                E = Fedgvtx0(:,3:4) - Fedgvtx0(:,1:2);

                % Get the edge slope with atan2
                E = atan2(E(:,2),E(:,1));

                % Initialize vars for the tests
                isL = zeros(nVc,3);  % is left?
                isR = isL;           % is right?
                isC = isL;           % is center?

                % For each edge of the current face, test if all other
                % points are on the left, right, or inline. Considers the
                % observer at the origin
                for e = 1:3,
                    V = Cvtx0(:,1:2) - repmat(Fedgvtx0(e,1:2),[nVc 1]); % Shift to the origin
                    V = atan2(V(:,2),V(:,1));     % Get the slope
                    D = mod(V-E(e),2*pi);         % Subtract, then wrap to between [0 2*pi]
                    isL(:,e) = D > 0 & D < pi;    % is Left
                    isR(:,e) = D > pi;            % is Right
                    isC(:,e) = D == 0 | D == pi;  % is in the line ("Center")
                end

                % For each candidate face in the current set...
                for cf = 1:nFc,  % cf here is different than above

                    % Check from the results above whether its
                    % vertices are all on the left of the edges of the current face (so,
                    % inside the triangle), or all on the right (so, outside), or some in and
                    % some out (so, partial overlap, with a need to compute their
                    % intersection in this case). Depending on the result, take
                    % apropriate action
                    cfisL = isL(Cfac0(cf,:),:);
                    cfisR = isR(Cfac0(cf,:),:);
                    cfisC = isC(Cfac0(cf,:),:);

                    if any(all(cfisR,1)),
                        % If all 3 points lie at the right of any edge,
                        % then they must be all outside. In this case, do
                        % nothing.
                        % Since this is a common case, to test it first
                        % prevents the next test from happening, and prevents
                        % the need to test all particular cases.

                    elseif all(cfisL(:) | cfisC(:)),
                        % If all 3 points are inside, then all will appear
                        % on the left of all edges.
                        % In this case, the target face inherit all what was within the
                        % candidate face in the source.
                        crv2(f) = crv2(f) + crv1(Cfaci(cf));

                        % Write the table with the overlaps to the disk
                        fprintf(fidolp,'%u %u %g %g %g\n',Cfaci(cf),f,apf1(Cfaci(cf)),apf1(Cfaci(cf)),apf2(f));

                    else
                        % For all the other situations:
                        % 1) One or two vertices inside
                        % 2) All vertices outside, with L/R alternating,
                        % such as in the David's star
                        % 3) All vertices outside, but still with some
                        % crossing edges
                        % The first task would be to compute all the
                        % intersections between edges, but this would
                        % require 9 tests. It can go faster by observing
                        % that edges of the current face (target) cannot be
                        % crossed if all the points of the candidate face
                        % (source) are on the left, which is known from the
                        % L/R test above. So, produce instead an intersection
                        % logical matrix. In the slowest case it will
                        % contain 6 true intersections (David's star shape),
                        % all the others should be 4 or 2, so the for-loop
                        % below is won't be so slow.
                        intidx = or( ...
                            and( ...
                            isL(Cfac0(cf,strp),:),  ...
                            isR(Cfac0(cf,endp),:)), ...
                            and( ...
                            isR(Cfac0(cf,strp),:),  ...
                            isL(Cfac0(cf,endp),:)));
                        [Cei,Fei] = ind2sub([3 3],find(intidx));

                        % Face edges with intersections to test
                        Fedgi = [Fvtx0(strp(Fei),1:2) Fvtx0(endp(Fei),1:2)];

                        % Candidate faces with intersections to test
                        Cedgi = [Cvtx0(Cfac0(cf,strp(Cei)),1:2) Cvtx0(Cfac0(cf,endp(Cei)),1:2)];

                        % Number of intersections, and allocate vars for
                        % the coordinates and if it's a valid intersection
                        nin  = numel(Cei);
                        xi = zeros(nin,1);
                        yi = xi;

                        % For each intersection
                        for in = nin:-1:1, % do it backwards to allow removal below
                            S1 = reshape(Fedgi(in,:),[2 2])';  % Segment 1
                            S2 = reshape(Cedgi(in,:),[2 2])';  % Segment 2
                            A = det(S1);   % Precompute some stuff (A, B and C)
                            B = det(S2);
                            C = [ ...
                                S1(1,:) - S1(2,:); ...
                                S2(1,:) - S2(2,:) ];
                            xi(in) = det([A C(1,1); B C(2,1)])/det(C);  % X coord of the intersection
                            yi(in) = det([A C(1,2); B C(2,2)])/det(C);  % Y coord of the intersection

                            % Check if the intersection is really between
                            % the segments or their extensions along their
                            % lines. This test could be outside the
                            % for-loop. However, inside it's possible to
                            % use short-circuit logic between scalars,
                            % which is faster and not possible with vectors
                            if      xi(in) < min(Fedgi(in,1),Fedgi(in,3)) || ...
                                    yi(in) < min(Fedgi(in,2),Fedgi(in,4)) || ...
                                    xi(in) > max(Fedgi(in,1),Fedgi(in,3)) || ...
                                    yi(in) > max(Fedgi(in,2),Fedgi(in,4)) || ...
                                    xi(in) < min(Cedgi(in,1),Cedgi(in,3)) || ...
                                    yi(in) < min(Cedgi(in,2),Cedgi(in,4)) || ...
                                    xi(in) > max(Cedgi(in,1),Cedgi(in,3)) || ...
                                    yi(in) > max(Cedgi(in,2),Cedgi(in,4)),

                                % If outside, remove this "false" intersection from
                                % further consideration
                                xi(in) = [];  yi(in) = [];
                            end
                        end

                        if numel(xi),
                            % Vertex indices of candidate face inside the target
                            % face. Together with the indices of the target
                            % vertices inside the candidate face and the
                            % intersection points, this define the
                            % overlapping area.
                            vtx_cf_in_f = all(cfisL,2);  % compare with vtx_f_in_cf above

                            % Put together the coordinates of the vertices
                            % inside the other face (reciprocal) and the
                            % intersections of the edges
                            Pxy = [ ...
                                Fvtx0(vtx_f_in_cf(cf,:),1:2); ...
                                Cvtx0(Cfac0(cf,vtx_cf_in_f),1:2); ...
                                [xi yi] ];

                            % Remove coincident points. Since these coordinates
                            % are all in the azimuthal gnomonic projection and
                            % since the faces are always small, it will be
                            % extremely rare to find any element on
                            % Pxy > tan(pi/3) = sqrt(3).
                            % To allow 'unique' to really remove
                            % repeated, and not keep them due to tiny floating
                            % point decimal places, and to avoid truncation of
                            % important information, scale Pxy, convert to
                            % single, remove repeated and test. If pass,
                            % then run qhull.
                            if size(unique(single(Pxy/max(abs(Pxy(:)))),'rows'),1) >= 3,

                                % Only if Pxy is still >=3, convert from azimutal
                                % gnomonic to radians, so that the areal distortion
                                % is minimized a bit more (though not removed)
                                %x = atan(Pxy(:,1)) .* meanR2;
                                %y = atan(Pxy(:,2)) .* meanR2;

                                % or keep gnomonic...
                                x = Pxy(:,1) .* meanR2;
                                y = Pxy(:,2) .* meanR2;

                                % Compute the convex hull (via qhull) and its area
                                if isoct,  % OCTAVE
                                    k = convhull(x,y,{'Pp'});
                                    areaint = polyarea(x(k),y(k));
                                else       % MATLAB
                                    [~,areaint] = convhull(x,y);
                                end

                                % Weight the attribute by the fraction of the intersecting area
                                crv2(f) = crv2(f) + crv1(Cfaci(cf)) * areaint/apf1(Cfaci(cf));

                                % Write the table with the overlaps to the disk
                                fprintf(fidolp,'%u %u %g %g %g\n',Cfaci(cf),f,areaint,apf1(Cfaci(cf)),apf2(f));
                            end
                        end
                    end
                end
            end
        end

        % Close the file with the overlaps
        fclose(fidolp);

        % Prepare to save the interpolated data
        crv2 = [(0:nF2-1)' facr crv2];


    case 'distributive',

        % Where the result is going to be stored
        crv2 = zeros(nV2,1);

        % Vertices' coords per face
        facvtx2 = [vtx2(fac2(:,1),:) vtx2(fac2(:,2),:) vtx2(fac2(:,3),:)];

        % Face barycenter
        cbary = [mean(facvtx2(:,[1 4 7]),2) ...  % Cartesian coordinates
            mean(facvtx2(:,[2 5 8]),2) mean(facvtx2(:,[3 6 9]),2)];
        [sbary(:,1),sbary(:,2),sbary(:,3)] = ... % Spherical coordinates
            cart2sph(cbary(:,1),cbary(:,2),cbary(:,3));

        % Pre-calculated sines and cosines of azimuth and elevation:
        sinA = sin(sbary(:,1));  sinE = sin(sbary(:,2));
        cosA = cos(sbary(:,1));  cosE = cos(sbary(:,2));

        % Pre-calculated rotation matrices
        rotM = [cosA.*cosE sinA.*cosE sinE -sinA cosA zeros(nF2,1) -cosA.*sinE -sinA.*sinE cosE];

        % Include a random angle around X, so that it prevents an issue with
        % perfectly horizontal edges
        rndangX = rand(1)*pi;
        sinX = sin(rndangX);
        cosX = cos(rndangX);
        rotM = [ rotM(:,1:3) ...
            rotM(:,4)*cosX+rotM(:,7)*sinX rotM(:,5)*cosX+rotM(:,8)*sinX rotM(:,6)*cosX+rotM(:,9)*sinX ...
            rotM(:,7)*cosX-rotM(:,4)*sinX rotM(:,8)*cosX-rotM(:,5)*sinX rotM(:,9)*cosX-rotM(:,6)*sinX ];

        % Pre-calc min and max for each face and bounding box with a tol margin
        minF = [min(facvtx2(:,[1 4 7]),[],2) ...
            min(facvtx2(:,[2 5 8]),[],2) min(facvtx2(:,[3 6 9]),[],2)];
        maxF = [max(facvtx2(:,[1 4 7]),[],2) ...
            max(facvtx2(:,[2 5 8]),[],2) max(facvtx2(:,[3 6 9]),[],2)];
        b = repmat(max((maxF-minF),[],2),[1 3]) * d.marg;  % <= marg enters here
        minF = minF-b;  maxF = maxF+b;

        % For each target face
        for f = 1:nF2;

            % Face vertices
            vidx = fac2(f,:);
            Fvtx = vtx2(vidx,:);

            % Identify vertices that fall within the bounding box (candidate vertices)
            Cidx = all(vtx1 >= repmat(minF(f,:),[nV1 1]) & ...
                vtx1 <= repmat(maxF(f,:),[nV1 1]), 2);
            Cvtx = vtx1(Cidx,:);
            Cidxi = find(Cidx); % Though slower than logical indexing, it'll be necessary below...

            % Rotate the face vertices and candidate vertices to near [r,0,0]
            Avtx = [Fvtx; Cvtx] * reshape(rotM(f,:),[3 3]);

            % The candidate vertex from the source, if found inside the face in
            % the target, has its value proportionally split across each of
            % the 3 vertices of the face in the target. Compare with the 'barycentric'
            % method below.

            % Convert to azimuthal gnomonic first
            Gvtx = ones(size(Avtx));           % The 3rd col will remain full of ones
            Gvtx(:,1) = Avtx(:,2)./Avtx(:,1);  % Tangent of the angle on the XY plane
            Gvtx(:,2) = Avtx(:,3)./Avtx(:,1);  % Tangent of the angle on the XZ plane
            T  = Gvtx(1:3,:);                  % Face coords for the test below
            aT = det(T);                       % Face total area (2x the area, actually)

            % For every candidate vertex
            for v = 1:numel(Cidxi),

                % Compute the areas for the subtriangles (2x area actually)
                tA = T;  tA(1,:) = Gvtx(v+3,:);  aA = abs(det(tA));  % Subtriangle A
                tB = T;  tB(2,:) = Gvtx(v+3,:);  aB = abs(det(tB));  % Subtriangle B
                tC = T;  tC(3,:) = Gvtx(v+3,:);  aC = abs(det(tC));  % Subtriangle C

                % Test if the point is inside the face
                if single(aT) == ...  % Single to avoid errors due to precision
                        single(aA + aB + aC);

                    % Weight appropriately by the areas and distribute the
                    % values across the 3 vertices, incrementing them
                    crv2(vidx) = crv2(vidx) + ...
                        crv1(Cidxi(v)) .* ([aA; aB; aC] ./ aT);
                end
            end
        end

        % Prepare to save
        crv2 = [(0:nV2-1)' vtxr crv2];


    case 'barycentric'

        % Where the result is going to be stored
        crv2 = zeros(nV2,1);

        % Vertices' coords per face
        facvtx1 = [vtx1(fac1(:,1),:) vtx1(fac1(:,2),:) vtx1(fac1(:,3),:)];

        % Face barycenter
        cbary = [mean(facvtx1(:,[1 4 7]),2) ...  % Cartesian coordinates
            mean(facvtx1(:,[2 5 8]),2) mean(facvtx1(:,[3 6 9]),2)];
        [sbary(:,1),sbary(:,2),sbary(:,3)] = ... % Spherical coordinates
            cart2sph(cbary(:,1),cbary(:,2),cbary(:,3));

        % Pre-calculated sines and cosines of azimuth and elevation:
        sinA = sin(sbary(:,1));  sinE = sin(sbary(:,2));
        cosA = cos(sbary(:,1));  cosE = cos(sbary(:,2));

        % Pre-calculated rotation matrices
        rotM = [cosA.*cosE sinA.*cosE sinE -sinA cosA zeros(nF1,1) -cosA.*sinE -sinA.*sinE cosE];

        % Include a random angle around X, so that it prevents an issue with
        % perfectly horizontal edges
        rndangX = rand(1)*pi;
        sinX = sin(rndangX);
        cosX = cos(rndangX);
        rotM = [ rotM(:,1:3) ...
            rotM(:,4)*cosX+rotM(:,7)*sinX rotM(:,5)*cosX+rotM(:,8)*sinX rotM(:,6)*cosX+rotM(:,9)*sinX ...
            rotM(:,7)*cosX-rotM(:,4)*sinX rotM(:,8)*cosX-rotM(:,5)*sinX rotM(:,9)*cosX-rotM(:,6)*sinX ];

        % Pre-calculated min and max for each face and bounding box
        minF = [min(facvtx1(:,[1 4 7]),[],2) ...
            min(facvtx1(:,[2 5 8]),[],2) min(facvtx1(:,[3 6 9]),[],2)];
        maxF = [max(facvtx1(:,[1 4 7]),[],2) ...
            max(facvtx1(:,[2 5 8]),[],2) max(facvtx1(:,[3 6 9]),[],2)];
        b = repmat(max((maxF-minF),[],2),[1 3]) * d.marg;  % <= marg enters here
        minF = minF-b;  maxF = maxF+b;

        % For each source face
        for f = 1:nF1;

            % Face vertices and associated scalars ("weights") from Curvature 1
            vidx = fac1(f,:);
            Fvtx = vtx1(vidx,:);

            % Candidate vertices
            Cidx = all(vtx2 >= repmat(minF(f,:),[nV2 1]) & ...
                vtx2 <= repmat(maxF(f,:),[nV2 1]), 2);
            Cvtx  = vtx2(Cidx,:);
            Cidxi = find(Cidx); % Though slower than logical indexing, it'll be necessary below...

            % Rotate the face vertices and candidate vertices
            Avtx = [Fvtx; Cvtx] * reshape(rotM(f,:),[3 3]);

            % Here is the main difference in relation to the 'distributive' method.
            % Instead of extrapolate (split) a point in the source into the face
            % vertices of the target for increments, find in the source
            % face what are the Target vertices that lie inside it and do a
            % barycentric interpolation (not to be confused with the rotation
            % of the barycenter, used some lines above to put the face under
            % analysis near the sphere equator and the meridian zero).

            % Convert to azimuthal gnomonic
            Gvtx = ones(size(Avtx));           % The 3rd col will remain full of ones
            Gvtx(:,1) = Avtx(:,2)./Avtx(:,1);  % Tangent of the angle on the XY plane
            Gvtx(:,2) = Avtx(:,3)./Avtx(:,1);  % Tangent of the angle on the XZ plane
            T  = Gvtx(1:3,:);                  % Face coords for the test below
            aT = det(T);                       % Face total area (2x the area, actually)

            % For every candidate vertex
            for v = 1:numel(Cidxi),

                % Compute the areas for the subtriangles (2x area actually)
                tA = T;  tA(1,:) = Gvtx(v+3,:);  aA = abs(det(tA));  % Subtriangle A
                tB = T;  tB(2,:) = Gvtx(v+3,:);  aB = abs(det(tB));  % Subtriangle B
                tC = T;  tC(3,:) = Gvtx(v+3,:);  aC = abs(det(tC));  % Subtriangle C

                % Test if the point is inside the face
                if single(aT) == ... % Single to avoid errors due to precision
                        single(aA + aB + aC);

                    % Weight appropriately by the areas and interpolate the
                    % value between the 3 vertices
                    crv2(Cidxi(v)) = [aA aB aC] * crv1(vidx) ./ aT;
                end
            end
        end

        % Prepare to save
        crv2 = [(0:nV2-1)' vtxr crv2];


    case 'nearest'  % Not to be confused with natural neighbour

        % Where to store the results
        crv2 = zeros(nV2,1);

        % Scale the source sphere to the same radius as the target
        [~,~,R1] = cart2sph(vtx1(:,1),vtx1(:,2),vtx1(:,3));
        meanR1 = mean(R1);
        [~,~,R2] = cart2sph(vtx2(:,1),vtx2(:,2),vtx2(:,3));
        meanR2 = mean(R2);
        vtx1 = vtx1 * (meanR2/meanR1);

        % The relation between Geodesic distance and Euclidean distance is
        % monotonic, so that the nearest geodesic neighbour is also the nearest
        % Euclidean neighbour.
        % The algorithm below is almost "the naive"..., it computes the distances
        % of every vertex to every other vertex. Takes forever to run. This
        % implementation, however, is not supposed to be used in practice,
        % except to prepare give a toy example for the paper in a small
        % sphere. For a faster implementation, use FreeSurfer or Spherical Demons.

        % For each target vertex
        for v = 1:nV2,

            % Current vertex, in the format to allow "quick" computation of
            % the Euclidean distance
            curvtx2 = repmat(vtx2(v,:),[nV1 1]);

            % Euclidean distance
            E = sum((curvtx2-vtx1).^2,2).^(1/2);

            % Value of the nearest neighbour(s)
            nnval = crv1(E == min(E));

            % It may happen that 2 or more vertices are all the nearest
            % neighbours. In this case, take the first that appears. This
            % is, in practice, random.
            crv2(v) = nnval(1);

        end

        % Prepare to save
        crv2 = [(0:nV2-1)' vtxr crv2];

    otherwise
        error('Method %s unknown. Use ''areal'', ''distributive'', ''barycentric'' or ''nearest''.',d.meth);
end

% Save the resulting interpolated curvature file
if isfield(d,'fcrv2') && ~isempty(d.fcrv2),
    fid = fopen(d.fcrv2,'w');
    fprintf(fid,'%0.3d %g %g %g %0.16f\n',crv2');
    fclose(fid);
end
