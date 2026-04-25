function angularADRCSmokeTest()
%ANGULARADRCSMOKETEST Basic interface smoke test for angularADRC.

params = struct( ...
    'Ts', 0.005, ...
    'wo', [60; 60; 50], ...
    'wc', [20; 20; 15], ...
    'b0', [17153; 13947; 10000], ...
    'alpha', 0.5, ...
    'delta', 0.01, ...
    'uMin', -0.02 * ones(3,1), ...
    'uMax', 0.02 * ones(3,1));

y = [0.05; -0.03; 0.01];
ref = [0.0; 0.0; 0.0];
ref_dot = [0.0; 0.0; 0.0];
u_prev = [0.0; 0.0; 0.0];
z_prev = zeros(3,3);

[tau_legacy, z_legacy] = angularADRC(y, u_prev, z_prev, params);
[tau_track, z_track, debug] = angularADRC(y, ref, ref_dot, u_prev, z_prev, params);

assert(isequal(size(tau_legacy), [3 1]));
assert(isequal(size(z_legacy), [3 3]));
assert(isequal(size(tau_track), [3 1]));
assert(isequal(size(z_track), [3 3]));
assert(isstruct(debug));

disp('angularADRCSmokeTest passed');
end
