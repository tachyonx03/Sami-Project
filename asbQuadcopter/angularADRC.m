function [tau_out, z, debug] = angularADRC(y, varargin)
%ANGULARADRC Channel-wise discrete ADRC for roll/pitch/yaw torque control.
%
% Supported call patterns:
%   [tau_out, z] = angularADRC(y, u_prev, z_prev, params)
%   [tau_out, z] = angularADRC(y, ref, ref_dot, u_prev, z_prev, params)
%
% Inputs:
%   y          measured states [3x1]
%   ref        reference states [3x1]
%   ref_dot    reference derivatives [3x1]
%   u_prev     previously applied torque [3x1]
%   z_prev     previous ESO states [3x3], each row = [z1 z2 z3]
%   params     ADRC parameter struct
%
% Output:
%   tau_out    commanded torque [3x1]
%   z          updated ESO states [3x3]
%   debug      diagnostic signals for logging/debugging

[ref, ref_dot, u_prev, z_prev, params] = localParseInputs(y, varargin{:});
wo = params.wo(:);
wc = params.wc(:);

b0 = params.b0(:);
Ts = params.Ts;
alpha = localFieldOr(params, 'alpha', 0.5);
delta = localFieldOr(params, 'delta', 0.01);
ref_weight = localFieldOr(params, 'refWeight', 1.0);

beta01 = 3 .* wo;
beta02 = 3 .* (wo .^ 2);
beta03 = wo .^ 3;
kp = wc .^ 2;
kd = 2 .* wc;

tau_out = zeros(3,1);
z = zeros(3,3);
debug = struct( ...
    'tracking_error', zeros(3,1), ...
    'rate_error', zeros(3,1), ...
    'disturbance_hat', zeros(3,1), ...
    'wo', wo, ...
    'wc', wc);

for i = 1:3
    z1 = z_prev(i,1);
    z2 = z_prev(i,2);
    z3 = z_prev(i,3);

    obs_err = z1 - y(i);

    % Discrete ESO update
    z1_next = z1 + Ts * (z2 - beta01(i) * obs_err);
    z2_next = z2 + Ts * (z3 - beta02(i) * fal(obs_err, alpha, delta) + b0(i) * u_prev(i));
    z3_next = z3 - Ts * beta03(i) * fal(obs_err, alpha, delta);

    tracking_err = ref_weight * ref(i) - z1_next;
    rate_err = ref_dot(i) - z2_next;
    u0 = kp(i) * tracking_err + kd(i) * rate_err;

    tau_cmd = (u0 - z3_next) / b0(i);
    tau_out(i) = localSaturate(tau_cmd, params, i);

    z(i,:) = [z1_next, z2_next, z3_next];
    debug.tracking_error(i) = tracking_err;
    debug.rate_error(i) = rate_err;
    debug.disturbance_hat(i) = z3_next;
end

end

function [ref, ref_dot, u_prev, z_prev, params] = localParseInputs(y, varargin)
nargs = numel(varargin);

switch nargs
    case 3
        % Legacy mode: no reference tracking input yet.
        u_prev = varargin{1};
        z_prev = varargin{2};
        params = varargin{3};
        ref = zeros(size(y));
        ref_dot = zeros(size(y));
    case 5
        ref = varargin{1};
        ref_dot = varargin{2};
        u_prev = varargin{3};
        z_prev = varargin{4};
        params = varargin{5};
    otherwise
        error(['angularADRC expects either 4 or 6 total inputs. ' ...
               'See function header for supported signatures.']);
end

ref = ref(:);
ref_dot = ref_dot(:);
u_prev = u_prev(:);
end

function value = localFieldOr(s, field_name, default_value)
if isfield(s, field_name)
    value = s.(field_name);
else
    value = default_value;
end
end

function u_sat = localSaturate(u, params, idx)
u_sat = u;

if isfield(params, 'uMin')
    u_sat = max(u_sat, params.uMin(idx));
end

if isfield(params, 'uMax')
    u_sat = min(u_sat, params.uMax(idx));
end
end

function out = fal(e, alpha, delta)
if abs(e) > delta
    out = sign(e) * abs(e)^alpha;
else
    out = e / delta^(1 - alpha);
end
end
