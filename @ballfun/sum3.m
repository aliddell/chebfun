function I = sum3(f, varargin)
% SUM3 Integration of a BALLFUN function over the unit ball. 
%   SUM3(F) is the integration of the BALLFUN function f over the
%   unit ball.
%
% See also SUM, SUM2.

% Copyright 2018 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

% Second argument: integral over the sphere of radius -1
[m,n,p] = size(f);

F = f.coeffs;

% Extract the 0-th Fourier mode
F = reshape(F(:,floor(n/2)+1,:), m, p);

% Multiply f par r^2sin(theta) (= Jacobian)
trig1 = trigtech( @(t) sin(pi*t));
Msin = trigspec.multmat(p, trig1.coeffs );
Mr2 = ultraS.multmat(m, chebfun(@(r) r.^2), 0 );
F = Mr2*F*(Msin.');

% Coefficients of integration between 0 and 1 of the chebyshev polynomials
IntChebyshev = zeros(1,m);
for i = 0:m-1
    if mod(i,4)==0
        IntChebyshev(i+1) = -1/(i^2-1);
    elseif mod(i,4)==1
        IntChebyshev(i+1) = 1/(i+1);
    elseif mod(i,4)==2
        IntChebyshev(i+1) = -1/(i^2-1);
    else
        IntChebyshev(i+1) = -1/(i-1);
    end
end

% Coefficients of integration between 0 and pi of the theta Fourier
% function
Listp = (1:p).' - floor(p/2)-1;
IntTheta = -1i*((-1).^Listp-1)./Listp;
IntTheta(floor(p/2)+1) = pi;

% Integrate over lambda
IntTheta = 2*pi*IntTheta;

% Integrate over the sphere of radius -1
if nargin>1
    IntChebyshev = (-1).^(0:m-1).*IntChebyshev;
end

% Return the integral of f over the ballfun
I = IntChebyshev*F*IntTheta;
end
