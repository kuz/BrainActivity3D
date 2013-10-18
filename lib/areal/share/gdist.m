function G = gdist(X,Y,R)
% Compute the geodesic distances between pairs of points X
% and Y on the surface of sphere(s) or radius R.
%
% Usage:
% G = gdist(X,Y,R)
%
% Inputs:
% X and Y = Euclidean coordinates for the set of points.
%           For P points in the D-dimensional space,
%           X and Y have size P by D, P > 0, D > 1.
% R       = Radius of the sphere(s) on which surface the distances
%           are measured. R can be a scalar, in which case the same
%           radius is used for all pairs of points, or can be a
%           vector size P, in which case, each pair of points will
%           be considered as lying on the surface of a sphere with a
%           different radius.
%           In either case, the set of P points are not assumed to be
%           all in the surface of the same sphere.
%
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Mar/2011
% http://brainder.org

% Accept inputs
if nargin~=3,
    error('Incorrect number of arguments.');
elseif ~all(size(X)==size(Y)),
    error('X and Y have to be of the same size.');
elseif size(X,2)<2,
    error('X and Y points have to be at least in 2D.');
elseif ~or(numel(R)==1,size(R,1)==size(X,1))
    error('R has to be a scalar or a vector with the same length as X and Y.');
end

% Adjust the size of R
if numel(R)==1,
    R = R * ones(size(X,1),1);
end

% Euclidean distance between the points
E = sum((X-Y).^2,2).^(1/2);

% Angle XOY, where O is the (unknown) center of the sphere
alpha = 2*asin(E./(2*R));

% Geodesic distance (length of the circular arc)
G = alpha .* R;  % simple, isn't it...!
