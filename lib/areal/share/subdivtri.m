function [vtx,fac] = subdivtri(vtx,fac,nlevels,newr)
% Subdivide progressively a triangular face into 4 subfaces, also triangular,
% using the midpoints of the edges of the previous iteraction as new vertices
% and project to the surface of a sphere of a given radius.
%
% Usage:
% [VTX,FAC] = subdivtri(VTX,FAC,NLEVELS,NEWR)
% - VTX,FAC = Vertex coordinates (VTX) and vertice indices for the faces (FAC).
% - NLEVELS = Number of iteractive subdivisions.
% - NEWR    = Circumradius of the sphere being created.
% 
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jan/2011
% http://brainder.org

% Ensure the radius is newr before beginning
[t,p,r] = cart2sph(vtx(:,1),vtx(:,2),vtx(:,3));
[vtx(:,1),vtx(:,2),vtx(:,3)] = sph2cart(t,p,ones(size(r))*newr);

% Recursively subdivide edges and project results to the
% surface of a sphere
for n = 1:nlevels,
    [vtx,fac] = splitface4(vtx,fac);
    vtx = proj2surf(vtx,newr);
end

% ========================================================================
function [vtx2,fac2] = splitface4(vtx,fac)
% Subdivide a triangular face into 4 subfaces, also triangular, using
% the midpoints of the edges as new vertices.

% Number of vertices, faces and edges
nV1 = size(vtx,1); nF1 = size(fac,1);
nE1 = nV1 + nF1 - 2; % Euler formula

% New numbers
nF2 = 4*nF1;
nE2 = 2*nE1 + 3*nF1;
nV2 = nE2 + 2 - nF2; % Euler formula again...

% Vertices per face
facvtx = [vtx(fac(:,1),:) vtx(fac(:,2),:) vtx(fac(:,3),:)];

% Edges' midpoints (new vertices)
midvtx = [
    (facvtx(:,1)+facvtx(:,4))/2 (facvtx(:,2)+facvtx(:,5))/2 (facvtx(:,3)+facvtx(:,6))/2 ...
    (facvtx(:,4)+facvtx(:,7))/2 (facvtx(:,5)+facvtx(:,8))/2 (facvtx(:,6)+facvtx(:,9))/2 ...
    (facvtx(:,1)+facvtx(:,7))/2 (facvtx(:,2)+facvtx(:,8))/2 (facvtx(:,3)+facvtx(:,9))/2 ];

% Remove repeated new vertices
newvtx = zeros(nV2-nV1,3);
midtmp = reshape(midvtx',[3 numel(midvtx)/3])';
for v = 1:size(newvtx,1),
    newvtx(v,:) = midtmp(1,:);
    midtmp(all(midtmp == repmat(newvtx(v,:),[size(midtmp,1) 1]),2),:) = [];
end

% New vertices matrix
vtx2 = [vtx; newvtx];

% Vertices per new face
facvtx2 = zeros(nF2,9);
for f = 1:nF1,
    facvtx2(4*f-3:4*f,:) = [
        facvtx(f,1:3) midvtx(f,1:3) midvtx(f,7:9);
        midvtx(f,1:3) facvtx(f,4:6) midvtx(f,4:6);
        midvtx(f,7:9) midvtx(f,4:6) facvtx(f,7:9);
        midvtx(f,1:9)];
end

% Convert vertices per new face to new vertex indices
facvtx2tmp = reshape(facvtx2',[3 numel(facvtx2)/3])';
factmp = zeros(nF2*3,1);
for v = 1:nV2,
    factmp(all(repmat(vtx2(v,:),[nF2*3 1]) == facvtx2tmp,2)) = v;
end
fac2 = reshape(factmp,[3 nF2])';
end

% ========================================================================
function vtx = proj2surf(vtx,newr)
% Project points to a spherical surface of predefined radius
[t,p,r] = cart2sph(vtx(:,1),vtx(:,2),vtx(:,3));
[vtx(:,1),vtx(:,2),vtx(:,3)] = sph2cart(t,p,ones(size(r))*newr);
end
end