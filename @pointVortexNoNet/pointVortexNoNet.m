classdef pointVortexNoNet < pointVortex
%pointVortexNoNet represents point vortices with no net circulation.
%
%  pv = pointVortex(location, strength)
%    Constructs a pointVortex object where location is a vector of points
%    located in a potential domain. The vector strength is a vector of
%    scalars the same size as the location vector indicating the strength
%    of each point vortex. The net added flow from the point vortices is
%    then assigned to a point vortex at a designated point in the
%    unitDomain (see the beta argument in the unitDomain constructor).
%
%See also potential, unitDomain, pointVortex.

% Everett Kropf, 2016
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

properties
    netPointVortex
    greensFunction
end

methods
    function pv = pointVortexNoNet(location, strength)
        if ~nargin
            args = {};
        else
            args = {location, strength};
        end
        pv = pv@pointVortex(args{:});
        
        pv.netPointVortex = pointVortex(args{:});
    end
end

methods(Hidden)    
    function val = evalPotential(pv, z)
        if pv.entirePotential
            val = evalPotential@pointVortex(pv, z);
            return
        end
        
        val = pv.netPointVortex.evalPotential(z);
        val = val - sum(pv.strength(:))*pv.greensFunction(z);
    end
    
    function dpv = getDerivative(pv)
        if pv.entirePotential
            dpv = getDerivative@pointVortex(pv);
            return
        end
        
        dg0v = diff(pv.greensFunction);
        dg0net = getDerivative(pv.netPointVortex);
        
        dpv = @(z) dg0net(z) - sum(pv.strength(:))*dg0v(z);
    end
    
    function pv = setupPotential(pv, W)
        Du = W.domain;
        if isempty(Du.infImage)
            error(PoTk.ErrorIdString.RuntimeError, ...
                'No image of infinity from the physical domain specified.')
        end
        
        pv.netPointVortex = pv.netPointVortex.setupPotential(W);
        pv.greensFunction = greensC0(Du.infImage, skpDomain(Du));
    end
end

methods(Hidden) % Documentation
    function str = latexExpression(pv)
        if pv.entirePotential
            str = latexExpression@pointVortex(pv);
            return
        end
        
        if numel(pv.location) == 1
            str = [...
                '\gamma \left( G_0(\zeta;\alpha,\overline{\alpha}) ', ...
                ' - G_0(\zeta;\beta,\overline{\beta}) \right)', ...
                ' \qquad\mathrm{(point\;vortex)}'];
        else
            str = [...
                '\sum_{k=1}^N \gamma_k ', ...
                '\left( G_0(\zeta;\alpha_k,\overline{\alpha_k}) ', ...
                ' - G_0(\zeta;\beta,\overline{\beta}) \right)', ...
                ' \qquad\mathrm{(point\; vortices)}'];
        end
    end
end

end
