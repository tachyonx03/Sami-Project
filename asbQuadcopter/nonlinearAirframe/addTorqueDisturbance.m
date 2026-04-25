% addTorqueDisturbance.m
% nonlinearAirframe의 AC model에 외부 토크 교란 입력(tau_ext)을 추가합니다.
%
% 수정 내용:
%   Motor Forces and Torques (out2) --> [Sum] --> M_cg
%                                tau_ext (Inport) --/
%
% Copyright 2024

modelName = 'nonlinearAirframe';
acPath    = [modelName '/Nonlinear/AC model'];

%% 1. 모델 로드
load_system(modelName);

%% 2. 기존 연결 (Motor Torques → M_cg) 삭제
delete_line(acPath, 'Motor Forces and Torques/2', 'M_cg/1');

%% 3. Sum 블록 추가
% Motor Forces and Torques 우측(x=540), M_cg 좌측(x=580) 사이에 배치
sumPos = [555, 548, 575, 582];
add_block('simulink/Math Operations/Sum', [acPath '/Torque Sum'], ...
    'Position',   sumPos,    ...
    'Inputs',     '++',      ...
    'IconShape',  'rectangular');

%% 4. Inport(tau_ext) 추가  — [3x1] N*m, body frame
inportPos = [370, 648, 400, 662];
add_block('simulink/Sources/In1', [acPath '/tau_ext'], ...
    'Position',       inportPos,  ...
    'PortDimensions', '[3 1]',    ...
    'OutDataTypeStr', 'double');

% 포트 번호를 기존 인풋 다음으로 설정 (현재 5개: Actuators/Environment/DCM_be/V_b/w_b)
set_param([acPath '/tau_ext'], 'Port', '6');

%% 5. 새 연결
add_line(acPath, 'Motor Forces and Torques/2', 'Torque Sum/1', 'autorouting', 'on');
add_line(acPath, 'tau_ext/1',                  'Torque Sum/2', 'autorouting', 'on');
add_line(acPath, 'Torque Sum/1',               'M_cg/1',       'autorouting', 'on');

%% 6. 상위 블록(Nonlinear)에 tau_ext 포트 연통
% AC model 서브시스템의 inport가 추가됐으므로 상위에서도 연결 필요
% → 일단 Terminator로 막아두고 나중에 실제 신호 연결
nonlinPath = [modelName '/Nonlinear'];
termPos    = [140, 248, 160, 262];
add_block('simulink/Sinks/Terminator', [nonlinPath '/tau_ext_src'], ...
    'Position', termPos);

% Nonlinear 서브시스템 내부에서 AC model의 6번 포트로 연결
% (Nonlinear 레벨에서 AC model 블록 포트 6 → Terminator 대신 Inport로 올릴 수도 있음)
% 지금은 Constant 0으로 막아서 기존 동작 보존
delete_block([nonlinPath '/tau_ext_src']);

constPos = [140, 243, 200, 263];
add_block('simulink/Sources/Constant', [nonlinPath '/tau_ext_zero'], ...
    'Position', constPos,    ...
    'Value',    '[0;0;0]',   ...
    'OutDataTypeStr', 'double');

add_line(nonlinPath, 'tau_ext_zero/1', 'AC model/6', 'autorouting', 'on');

%% 7. 저장
save_system(modelName);
disp('완료: nonlinearAirframe에 tau_ext 입력이 추가됐습니다.');
disp('교란 주입: nonlinearAirframe/Nonlinear/tau_ext_zero 의 Value를 변경하세요.');
