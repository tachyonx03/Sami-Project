% addAngleScope.m
% flightControlSystem 모델에 목표각/측정각 비교 Scope를 추가합니다.
%
% 사용법:
%   addAngleScope        % 추가
%   addAngleScope('remove')  % 제거
%
% Copyright 2024

function addAngleScope(action)

if nargin < 1, action = 'add'; end

modelName = 'flightControlSystem';
load_system(modelName);

% 추가할 블록 경로
scopePath   = [modelName '/AngleScope'];
muxPath     = [modelName '/AngleMux'];
selRefPath  = [modelName '/SelOrientRef'];
selEulPath  = [modelName '/SelEuler'];

%% 제거 모드
if strcmp(action, 'remove')
    blocks = {scopePath, muxPath, selRefPath, selEulPath};
    for b = blocks
        try
            lines = get_param(b{1}, 'LineHandles');
            f = fields(lines);
            for ff = f'
                lh = lines.(ff{1});
                lh = lh(lh > 0);
                delete_line(lh);
            end
            delete_block(b{1});
        catch
        end
    end
    save_system(modelName);
    disp('AngleScope 제거 완료');
    return;
end

%% 추가 모드
% ── 모델 내 Command버스와 States버스 포트를 찾기 위해 블록 목록 확인
allBlocks = find_system(modelName, 'SearchDepth', 1, 'Type', 'block');
disp('최상위 블록 목록:');
disp(allBlocks);

% Command 버스를 내보내는 블록 이름 (일반적으로 'Flight Controller' 또는 유사)
% States 버스는 nonlinearAirframe에서 옴
% → 사용자가 직접 신호 이름 확인 후 아래 SignalName을 수정하세요.

% ── Bus Selector: orient_ref (목표각)
add_block('simulink/Signal Routing/Bus Selector', selRefPath, ...
    'Position', [1100, 100, 1150, 130]);
set_param(selRefPath, 'OutputSignals', 'orient_ref');

% ── Bus Selector: Euler (측정각)
add_block('simulink/Signal Routing/Bus Selector', selEulPath, ...
    'Position', [1100, 200, 1150, 230]);
set_param(selEulPath, 'OutputSignals', 'Euler');

% ── Mux: 두 신호 합치기 (각각 3채널 → 총 6채널)
add_block('simulink/Signal Routing/Mux', muxPath, ...
    'Position', [1200, 120, 1210, 210], ...
    'Inputs', '2');

% ── Scope
add_block('simulink/Sinks/Scope', scopePath, ...
    'Position', [1260, 150, 1310, 180], ...
    'NumInputPorts', '2');

% Scope 채널 설정 (6채널: ref×3, euler×3)
scopeConfig = get_param(scopePath, 'ScopeSpecificationObject');
if ~isempty(scopeConfig)
    scopeConfig.NumInputPorts = 2;
end

% ── 연결: BusSelector → Mux → Scope
add_line(modelName, [selRefPath(length(modelName)+2:end) '/1'], ...
                    [scopePath(length(modelName)+2:end)  '/1'], 'autorouting', 'on');
add_line(modelName, [selEulPath(length(modelName)+2:end) '/1'], ...
                    [scopePath(length(modelName)+2:end)  '/2'], 'autorouting', 'on');

save_system(modelName);

disp('=================================================');
disp('AngleScope 추가 완료.');
disp('');
disp('※ 다음 단계가 필요합니다:');
disp('  1. Simulink에서 flightControlSystem을 열어');
disp('     SelOrientRef의 입력 포트를 Command 버스에 연결');
disp('     SelEuler의 입력 포트를 States 버스에 연결');
disp('  2. 또는 더 간단히: plotAngles.m 방법을 사용하세요');
disp('=================================================');
end
