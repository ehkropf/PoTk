classdef uniformFlow < pointSingularity
%circulationNoNet removes net circulation from unit circle.
%
%  C = circulation(c0, c1, c2, ..., cm)
%  C = circulation([c0, c1, c2, ..., cm])
%    Creates a circulation object which describes the potential
%    contribution due to circulation around m inner circles and the unit
%    circle. For j = 0:m, each cj is a real scalar value specifying the
%    circulation strength on the jth circle. The net circulation is then
%    assigned to a designated point in the domain (see the beta argument
%    in the unitDomain constructor).
%
%See also potential, unitDomain, circulation.

% Everett Kropf, 2016
% Rhodri Nelson, 2016
% 
% This file is part of the Potential Toolkit (PoTk).
% 
% PoTk is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% PoTk is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with PoTk.  If not, see <http://www.gnu.org/licenses/>.

properties(SetAccess=protected)
    angle = 0
    scale = 1
    
    ufbvp
end

properties(Access=private)
    forSimplyConnected = false
    scaleWasGiven = false
    scaleWarningGiven = false
end

methods
    function uf = uniformFlow(location, strength, angle, scale)
        if ~nargin
            return
        end
        
        if nargin > 3
            uf.scaleWasGiven = true;
            uf.scale = scale;
        end
        
        if numel(location) ~= 1
            error(PoTk.ErrorIdString.RuntimeError, ...
                'Location must be a single point.')
        end
        uf.location = location;
        
        if ~(numel(strength) == 1 && imag(strength) == 0)
            error(PoTk.ErrorIdString.RuntimeError, ...
                'Flow speed must be a real scalar.')
        end
        uf.strength = strength;
        
        if nargin > 2
            uf.angle = angle;
        end
    end
    
    function uf = struct(uf)
        %Convert instance to structure.
        
        chi = uf.angle;
        uf = struct@pointSingularity(uf);
        uf.angle = chi;
    end
end

methods(Hidden)
    function val = evalPotential(uf, z)
           
        val = complex(zeros(size(z)));
        
        U = uf.strength;
        if U == 0
            return
        end
               
        chi = uf.angle;
        a = uf.scale;
        
        if uf.entirePotential
            val = U*exp(-1i*chi).*z;
            return
        end
        
        if ~uf.scaleWasGiven
            uf.scaleWarning()
        end
        
        if uf.forSimplyConnected
            if beta == 0
                val = U*(conj(a)*exp(1i*chi)*z + a*exp(-1i*chi)./z);
            elseif (abs(beta) > 1.0-2*eps) && (abs(beta) < 1.0+2*eps)
                val = 0.5*U*(-conj(a)*exp(1i*chi)./(conj(beta).^2.*(z - 1/conj(beta))) ...
                         + a*exp(-1i*chi)./(z-beta));
            else
                val = U*(-conj(a)*exp(1i*chi)./(conj(beta).^2.*(z - 1/conj(beta))) ...
                         + a*exp(-1i*chi)./(z-beta));   
            end
            return
        end

        val = uf.ufbvp(z);

    end
    
    function duf = getDerivative(uf)
    
        beta = uf.location;
        U = uf.strength;
        chi = uf.angle;
        a = uf.scale;
        
        if uf.entirePotential
            duf = U*exp(-1i*chi);
            return
        end
        
        if ~uf.scaleWasGiven
            uf.scaleWarning()
        end
        
        if uf.forSimplyConnected
            if beta == 0
                duf = @(z) U*(conj(a)*exp(1i*chi) - a*exp(-1i*chi)./z.^(2));
            elseif (abs(beta) > 1.0-2*eps) && (abs(beta) < 1.0+2*eps)
                duf = @(z) 0.5*U*(-a*exp(-1i*chi)*(1./(z - beta).^2) ...
                    + conj(a)*exp(1i*chi)*1./(conj(beta).^2.*(z - 1/conj(beta)).^2));
            else
                duf = @(z) U*(-a*exp(-1i*chi)*(1./(z - beta).^2) ...
                    + conj(a)*exp(1i*chi)*1./(conj(beta).^2.*(z - 1/conj(beta)).^2));
            end    
            
            return
        end
        
        ut = uf.ufbvp;
        dufh = diffh(ut);
        function v = dEval(z)
            v = dufh(z);
            if (abs(beta) > 1.0-2*eps) && (abs(beta) < 1.0+2*eps)
                v = v + 0.5*U*(-a*exp(-1i*chi)*(1./(z - beta).^2) ...
                      + conj(a)*exp(1i*chi)*1./(conj(beta).^2.*(z - 1/conj(beta)).^2));
            else
                v = v + U*(-a*exp(-1i*chi)*(1./(z - beta).^2) ...
                      + conj(a)*exp(1i*chi)*1./(conj(beta).^2.*(z - 1/conj(beta)).^2));
            end
        end
        
        duf = @dEval;
        
    end
    
    function uf = setupPotential(uf, W)
        D = W.unitDomain;
        beta = uf.location;
        if ~isin(D, beta)
            error(PoTk.ErrorIdString.RuntimeError, ...
                'The dipole must be located inside the bounded circle domain.')
        end
        
        if uf.strength == 0
            return
        end
        if D.m == 0
            d.forSimplyConnected = true;
            return
        end
        U = uf.strength;
        chi = uf.angle;
        a = uf.scale;
        D = skpDomain(D);
        uf.ufbvp = PoTk.uniformFlowBVP(beta, U, chi, a, D);
    end
end

methods(Access=protected)
    function scaleWarning(d)
        if d.scaleWarningGiven
            return
        end
        
        % FIXME: Really need a new ID string for this message.
        warning('PoTk:UniformFlow:noScale', ...
                ['A scale for class %s should be specified ', ...
                'if there is a map to a physical domain, potential ', ...
                'since it may otherwise be inaccurate. Scale set to 1 ', ...
                'by default.'], class(uf))
        uf.scaleWarningGiven = true;
    end
    
    function bool = getOkForPlane(~)
        bool = true;
    end
end

end