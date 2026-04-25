% plotAngles.m
% 시뮬레이션 결과(out)에서 목표각과 측정각을 비교 플롯합니다.
%
% 사용법:
%   out = sim('nonlinearAirframe');
%   plotAngles(out)
%
% Copyright 2024

function plotAngles(out)

%% logsout에서 신호 추출 시도
logs = out.logsout;
names = {};
for i = 1:logs.numElements
    names{end+1} = logs.getElement(i).Name;
end

fprintf('logsout에 있는 신호 목록:\n');
disp(names');

%% Euler (측정각)
eulIdx = find(contains(names, 'Euler') | contains(names, 'euler'));
if isempty(eulIdx)
    % StatesBus 통째로 들어오는 경우
    eulIdx = find(contains(names, 'States') | contains(names, 'states'));
end

if isempty(eulIdx)
    error(['Euler 신호를 찾지 못했습니다.' newline ...
           '위 신호 목록을 보고 정확한 이름을 확인하세요.']);
end

eul_el = logs.getElement(eulIdx(1));
t_eul  = eul_el.Values.Time;
euler  = eul_el.Values.Data;   % N×3

%% orient_ref (목표각)
refIdx = find(contains(names, 'orient_ref') | contains(names, 'orientRef'));
if isempty(refIdx)
    refIdx = find(contains(names, 'Command') | contains(names, 'command'));
end

if isempty(refIdx)
    error(['orient_ref 신호를 찾지 못했습니다.' newline ...
           '위 신호 목록을 보고 정확한 이름을 확인하세요.']);
end

ref_el = logs.getElement(refIdx(1));
t_ref  = ref_el.Values.Time;
ref    = ref_el.Values.Data;   % N×3

%% 플롯
axName = {'Roll (\phi)', 'Pitch (\theta)', 'Yaw (\psi)'};
figure('Name','목표각 vs 측정각','NumberTitle','off','Position',[100 100 900 650]);

for i = 1:3
    subplot(3,1,i);
    plot(t_ref, rad2deg(ref(:,i)),   'b-',  'LineWidth',1.5, 'DisplayName','목표각'); hold on;
    plot(t_eul, rad2deg(euler(:,i)), 'r--', 'LineWidth',1.5, 'DisplayName','측정각');
    ylabel([axName{i} ' [deg]']);
    legend('Location','best');
    grid on;
end
xlabel('Time [s]');
sgtitle('목표각 vs 측정각 비교');

end
