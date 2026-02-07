function logEvent(~, level, eventName, payload)
%LOGEVENT Minimal structured log helper.
if nargin < 2
    level = 'INFO';
end
if nargin < 3
    eventName = 'event';
end
if nargin < 4
    payload = struct();
end
entry = struct('ts', datetime('now'), 'level', string(level), 'event', string(eventName), 'payload', payload);
disp(entry);
end
