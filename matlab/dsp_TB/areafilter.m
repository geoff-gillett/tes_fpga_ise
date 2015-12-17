function indexes = areafilter(area)
%AREAFILTER Summary of this function goes here
%   Detailed explanation goes here

pulsemeasurements = evalin('base','pulsemeasurements');

indexes=[];
for i=1:length(pulsemeasurements)
    if pulsemeasurements(i,1) >= area
        indexes=[indexes i];
    end
end

