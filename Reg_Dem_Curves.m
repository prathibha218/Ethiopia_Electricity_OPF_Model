%% Regional Demand Curve Calculations 
%Thesis Title: An Optimal Power Flow Model to Guide  Electricity Grid 
%Expansion in Ethiopia for Groundwater Irrigation Use
%Author: Prathibha Juturu
%Description: This code calculates regional demand curves for each of the
%13 regions in the MME model. (Note: Werder is excluded because irrigation
%demand is 0 MW and it is not connected to the national electricity grid).
%Part 1: calculate the hourly irrigation demand (MW) for wet and dry seasons
%Part 2: calculate regional peak demand (MW) and uses that to create the
%regional demand curves
%Part 3: combine the regional demand curves and hourly irrigation demand 
%Part 4: add export demand to array 
%Part 5: match region number to the bus number in GAMS input data

clear all

format shortG
%% Part 1: Hourly Irrigation Demand Calculation in Wet and Dry Seasons 
% Check 5.3 Groundwater Irrigation Demand for process to calculate the
% electricity demand for groundwater irrigation 

% Loading data
% Need to rearrange to start row 1 with Oct 1  
% Column #:     Region Name:
%   1              Asosa
%   2              Awasa
%   3              Bahir Dar
%   4              Dire Dawa
%   5              Gambela
%   6              Goba
%   7              Gondar
%   8              Harar
%   9              Jijiga
%   10             Jimma
%   11             Mekelle
%   12             Semera
%   13             Addis Ababa 

x = csvread('irrig_elec_2018_2.csv', 1, 1); %removes row 1 and column 1 headings
A = 13; %row and column length of data 

%% Averaging irrigation demand (MW) over days in wet season and dry season 
% 1-243 corresponds to Oct 1, 2018 - Dec 31, 2018 and Jan 1 2018- May 31, 2018
% 244 - 365 corresponds to June 1, 2018 to September 20, 2018

for i = 1:A %each region
        dryhourlyMW(i) = (sum(x([1:243],i))/(243*24))*1000; 
        %average daily irrigation load for dry season (MW)
end

for i = 1:A %each region
        wethourlyMW(i) = (sum(x([244:365],i))/((365-243)*24))*1000; 
        %average daily irrigation load for wet season (MW)
end
%*Delete below 
% for i = 1:A %each region
%         dryhourlyMW(i) = 0;
%         %average daily irrigation load for dry season (MW)
% end
% 
% for i = 1:A %each region
%         wethourlyMW(i) = 0;
%         %average daily irrigation load for wet season (MW)
% end


% dry = dryhourlyMW;
% wet = wethourlyMW;
% dry = array2table(dry');
% wet = array2table(wet');
% 
% filename2 = ('Hourly_Irr_Dem.xlsx');
% writetable(dry, filename2, 'Sheet', 1);
% writetable(wet, filename2, 'Sheet', 2);

%Plotting bar graph for dry and wet season irrigation demand (MW)
for i = 1:length(dryhourlyMW)
    Y(i,1) = dryhourlyMW(i);

    Y(i,2) = wethourlyMW(i);
end

figure (3)
X = categorical({'Asosa', 'Awasa', 'Bahir Dar', 'Dire Dawa', 'Gambela', 'Goba', 'Gondar', ...
'Harar','Jjiga', 'Jimma', 'Mekelle', 'Semera', 'Addis Ababa'});
X = reordercats(X,{'Asosa', 'Awasa', 'Bahir Dar', 'Dire Dawa', 'Gambela', 'Goba', 'Gondar', ...
'Harar','Jjiga', 'Jimma', 'Mekelle', 'Semera', 'Addis Ababa'}); 
bar(X,10*Y)
legend('Dry season', 'Wet season')
title('Hourly Electricity Demand for Groundwater Irrigation (MW)')
xlabel('Region')
ylabel('Load (MW)')
ylim([0 500])

%% Part 2: Creating regional demand curves 
% Check Section 5.6 Regional Demand 24-hour Load Curve for calculation
% process

% Calculating regional peak demand
%Peak demand Addis is 60% of country peak demand 
%(Source:https://pubs.naruc.org/pub.cfm?id=537C14D4-2354-D714-511E-CB19B0D7EBD9)
%Need to disaggregate 40% of country peak demand according to regional
%population

Pop = 79123151;     %Total country population excluding Werder and Addis
%(Source: CIESIN 2015 UN adjusted gridded population)

P =  csvread('Ethiopia_Regional_population.csv', 1, 1); %loading percentage of 
%population in each region excluding Addis Ababa (Calculated from CIESIN raster)

P_percent = P/Pop;

%*Tot_elec_17 = 10000;        % (GWh) 2017 total electricity consumption (Source: IEA)

%Below are the options for peak demand 
%Tot_peak_calc = 1632;    % (MW) 2017 peak demand check research notes for this calculation
%Tot_peak_calc = 5206;    % (MW) future demand 2027 n = 10
%Tot_peak_calc = 3676;    % (MW) future demand 2024 n = 7
Tot_peak_calc = 2058;     % (MW) future demand 2019 n = 2
%Tot_peak_17_source = 5000;  % (MW) (Source:https://pubs.naruc.org/pub.cfm?id=537C14D4-2354-D714-511E-CB19B0D7EBD9)

Reg_peak = P_percent*Tot_peak_calc*0.4; %disaggregating 40% of the total peak demand 
Reg_peak(13) = 0.6*Tot_peak_calc;        %peak demand for Addis in 2017

%% Creating regional demand curves
%Two peak periods: 1) 11AM-2PM 2)7-9PM 
%graph of 24 hour load curve in source below 
%(Source:https://pubs.naruc.org/pub/5379AB21-2354-D714-5178-2172830B66EA)

% Hourly points as percentage of peak demand (starts at 1AM)
h = 1:24;
hour_percent = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 1 1 1 1 0.75 0.75 0.75 0.75 1 1 1 0.5 0.5 0.5];

%*hour_percent = [0.5 0.5 0.5 0.5 0.5 0.5833 0.6666 0.7499 0.8332 0.9165 1 1 1 1 0.85 0.85 0.85 0.85 1 1 1 0.8333 0.6667 0.5];

%Plotting the daily load curve proportion to peak demand
figure (1)
plot(h, hour_percent)
title('2019  Daily Load Curve')
xlabel('Hours (1-24)')
ylabel('Domestic Peak Demand (MW)')


for i = 1:length(Reg_peak)
    for h = 1:24 
    Reg_dem_curve(i,h) = Reg_peak(i)*hour_percent(h);
    end
end
z =  Reg_dem_curve([1:13],:);

%Domestic regional load curve 
figure (2) 
hold on
for ii = 1:13
 plot(z(ii,:))
end
legend('Asosa', 'Awasa', 'Bahir Dar', 'Dire Dawa', 'Gambela', 'Goba', 'Gondar', ...
'Harar','Jjiga', 'Jimma', 'Mekelle', 'Semera', 'Addis Ababa') 
title('Regional load curves for 2019 (MW)')
xlabel('Hours (1-24)')
ylabel('Load (MW)')

%Reformats the regional load curve 
for h = 1:24
    for i = 1:length(Reg_peak)
        Reg_dem_hourly((i-1)*24 + h,3) = Reg_dem_curve(i, h); 
        Reg_dem_hourly((i-1)*24 + h,2) = h;
        Reg_dem_hourly((i-1)*24 + h,1) = i;
    end
end


%*v = sum(Reg_dem_hourly(:,3))*365/1000
%*checking to see yearly total matches with 10,000 GWh (IEA 2018) estimate
%*Above is converted from MWh to GWh

%% Part 3: Combining regional demand curve and hourly irrigation demand 

%Combining the domestic regional demand and the groundwater irrigation
% demand 
for h = 1:24
    for i = 1:length(Reg_peak)
        Tot_dem_dry((i-1)*24 + h,3) = 10*dryhourlyMW(i) + Reg_dem_hourly((i-1)*24 + h,3);
        Tot_dem_dry((i-1)*24 + h,1) = i;
        Tot_dem_dry((i-1)*24 + h,2) = h;
        Tot_dem_wet((i-1)*24 + h,3) = 10*wethourlyMW(i) + Reg_dem_hourly((i-1)*24 + h,3);
        Tot_dem_wet((i-1)*24 + h,1) = i;
        Tot_dem_wet((i-1)*24 + h,2) = h;
    end
end



%* % Checking to see if added irrigation load is correct 
% d = sum(dryhourlyMW)*243*24/1000;
% u = sum(wethourlyMW)*(365-243)*24/1000;
% w = (sum(Tot_dem_dry(:,3))*243 + sum(Tot_dem_wet(:,3))*(365-243))/1000; 
% tot = d+u;

%% Part 4: Adding export demands
%Check Section 5.5 Exports for export demand values
%Two options for export demands
%export = [100 0 100 0];

export = [200 1000 100 400];
for x = 1:length(export)    
    for h = 1:24
        Tot_dem_dry(312+(x-1)*24+h,1) = 13+x; 
        Tot_dem_dry(312+(x-1)*24+h,2) = h;
        Tot_dem_dry(312+(x-1)*24+h,3) = export(x);
        Tot_dem_wet(312+(x-1)*24+h,1) = 13+x; 
        Tot_dem_wet(312+(x-1)*24+h,2) = h;
        Tot_dem_wet(312+(x-1)*24+h,3) = export(x);
    end
end


%% Part 5: Matching region number to the bus number in GAMS input data 
% Column #:     Region Name:    bus #:
%   1              Asosa         7
%   2              Awasa         10
%   3              Bahir Dar     13
%   4              Dire Dawa     3
%   5              Gambela       12
%   6              Goba          9
%   7              Gondar        8
%   8              Harar         5
%   9              Jijiga        4
%   10             Jimma         11
%   11             Mekelle       1
%   12             Semera        2
%   13             Addis Ababa   6
%   14             Sudan N       17
%   15             Sudan S       18
%   16             Djibouti      20
%   17             Kenya         19

M = size(Tot_dem_dry);
for i = 1:M(1)
if Tot_dem_dry(i,1) == 1
   Tot_dem_dry(i,1) = 7;
   Tot_dem_wet(i,1) = 7;
elseif Tot_dem_dry(i,1) == 2
   Tot_dem_dry(i,1) = 10;
   Tot_dem_wet(i,1) = 10;
elseif Tot_dem_dry(i,1) == 3
   Tot_dem_dry(i,1) = 13;
   Tot_dem_wet(i,1) = 13;    
elseif Tot_dem_dry(i,1) == 4
   Tot_dem_dry(i,1) = 3;
   Tot_dem_wet(i,1) = 3;
elseif Tot_dem_dry(i,1) == 5
   Tot_dem_dry(i,1) = 12;
   Tot_dem_wet(i,1) = 12;
elseif Tot_dem_dry(i,1) == 6
   Tot_dem_dry(i,1) = 9;
   Tot_dem_wet(i,1) = 9;
elseif Tot_dem_dry(i,1) == 7
   Tot_dem_dry(i,1) = 8;
   Tot_dem_wet(i,1) = 8;
elseif Tot_dem_dry(i,1) == 8
   Tot_dem_dry(i,1) = 5;
   Tot_dem_wet(i,1) = 5;
elseif Tot_dem_dry(i,1) == 9
   Tot_dem_dry(i,1) = 4;
   Tot_dem_wet(i,1) = 4;
elseif Tot_dem_dry(i,1) == 10
   Tot_dem_dry(i,1) = 11;
   Tot_dem_wet(i,1) = 11;
elseif Tot_dem_dry(i,1) == 11
   Tot_dem_dry(i,1) = 1;
   Tot_dem_wet(i,1) = 1;
elseif Tot_dem_dry(i,1) == 12
   Tot_dem_dry(i,1) = 2;
   Tot_dem_wet(i,1) = 2;
elseif Tot_dem_dry(i,1) == 13
   Tot_dem_dry(i,1) = 6;
   Tot_dem_wet(i,1) = 6;
elseif Tot_dem_dry(i,1) == 14 % Sudan N 
   Tot_dem_dry(i,1) = 17 ;
   Tot_dem_wet(i,1) = 17 ;   
elseif Tot_dem_dry(i,1) == 15 % Sudan S 
   Tot_dem_dry(i,1) = 18 ;
   Tot_dem_wet(i,1) = 18 ;
elseif Tot_dem_dry(i,1) == 16 % Djibouti 
   Tot_dem_dry(i,1) = 20 ;
   Tot_dem_wet(i,1) = 20 ;
elseif Tot_dem_dry(i,1) == 17 % Kenya 
   Tot_dem_dry(i,1) = 19 ;
   Tot_dem_wet(i,1) = 19 ;
end
end

%Writing into excel file 
Tot_dem_dry = array2table(Tot_dem_dry);
Tot_dem_wet = array2table(Tot_dem_wet);

filename = 'Model5_demand.xlsx';
writetable(Tot_dem_dry,filename,'Sheet',1);
writetable(Tot_dem_wet,filename,'Sheet',2);

%%Calculating total annual electricity consumption 
peaks = [1632 5206 3676 2058];
%2017/2027/2024/2019
e = [200 1700];

hour_percent = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 1 1 1 1 0.75 0.75 0.75 0.75 1 1 1 0.5 0.5 0.5];
v = (365/1000)*sum(hour_percent*peaks(2) + e(1)) + sum(dryhourlyMW)*(24*243/1000) + sum(wethourlyMW)*(24*(365-243)/1000)


%baseline: 11581 
%S1 - 13120
%S2 - 26260
%S3 - 34644
%S4 - 38570
%S5 - 42674
