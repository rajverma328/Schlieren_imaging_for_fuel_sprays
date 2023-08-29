clear all
close all
warning('off')
t=0;
Area_limit=500;
r = [0,0,0,0];
r1 = 0;
%%%%%%%%%%%%%%%%%%%%%%%%% taking input %%%%%%%%%%%%%%%%%%%%%%%%%
prompt = {'Enter length calibration factor (mm/pixel)','Enter frame rate in f.p.s.','Enter threshold senstivity','enter circle distance value(pixels)'};
dlgtitle = 'Input';
dims = [1 50];
definput = {'0.2008','15000','7','450'};  %(197/7.5)^-1 as provided
answer = inputdlg(prompt,dlgtitle,dims,definput);
calibration_factor = str2double(answer(1));
frame_rate = str2double(answer(2));
rcor = str2double(answer(3));
area_cal_fac = calibration_factor*calibration_factor;
frame_rate = frame_rate/1000; %frames per milli second
frame_rate = 1/frame_rate;
cds = str2double(answer(4));

data_filename = uigetdir; % filename for all folders
topLevelFolder = data_filename;  % Get a list of all files and folders in this folder.
files = dir(topLevelFolder);    % Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];   % Extract only those that are directories.
subFolders = files(dirFlags);   % A structure with extra info. Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name}; % Start at 3 to skip . and ..
cola = {'A2' 'B2' 'C2' 'D2' 'E2' 'F2' 'G2' 'H2'};
cola2 = {'J2' 'K2' 'L2' 'M2' 'N2' 'O2' 'P2' 'Q2'};
cola3 = {'S2' 'T2' 'U2' 'V2' 'W2' 'X2' 'Y2' 'Z2'};
cola4 = {'AB2' 'AC2' 'AD2' 'AE2' 'AF2' 'AG2' 'AH2' 'AI2' 'AJ2' 'AK2' 'AL2' 'AM2' 'AN2' 'AO2' 'AP2' 'AQ2'};
col_count = 1;
xcl = strcat(data_filename,'\results_test_13April.xlsx'); 
l2 = length(subFolderNames);

tavg = [];
areaavg =[];
area_speedavg =[];
periavg =[];
peri_speedavg =[];
ypavg =[];
speedypavg =[];
wavg =[];

for index = 1:l2
    blsh = '\';
    path = strcat(data_filename,blsh,subFolderNames(index));
    path = string(path);
    tif_files = dir(fullfile(path,'*.tif'));
    l = length(tif_files);
    bg_img1 = rgb2gray(imread(fullfile(path,tif_files(1).name)));
    [rows ,cols ,~] = size(bg_img1);
    targetSize = [cds cds];
    r = centerCropWindow2d(size(bg_img1),targetSize);
    bg_img1 = imcrop(bg_img1,r);
    sheet = string(subFolderNames(index));
    sheet = strrep(sheet,'.','_');
    chr = convertStringsToChars(sheet);
    if (length(chr) > 29)
        sheet = string(chr(1:30));
    end
    destdirectory1 = strcat(path,'\processed BW');
    destdirectory3 = strcat(path,'\processed edge');
    destdirectory2 = strcat(path,'\processed contour');
    mkdir(destdirectory1); %create the directory
    mkdir(destdirectory2);
    mkdir(destdirectory3);

    area = [];
    peri = [];
    xp = [];
    xn = [];
    yp = [];
    yn = [];
    t = [];
    tc = 0;
    for cnt = 1:l %replace by l to iterate 
        img = imread(fullfile(path,tif_files(cnt).name));
        r = centerCropWindow2d(size(img),targetSize);
        img = imcrop(img,r);
        gray2 = rgb2gray(img);
        gray3 = bg_img1-gray2; 
        gray1 = medfilt2(gray3);
        gray1 = gray1>rcor;
        se = strel('disk',10);
        gray1 = imclose(gray1,se);
        gray1 = imfill(gray1,"holes");
        BWfinal = edge(gray1,'sobel');
        ctr = sum(BWfinal(:));
        if ctr == 0
            continue;
        end
        tc = tc+1;
        t = [t;tc*frame_rate];
        area = [area; area_cal_fac*bwarea(gray1)];
        peri = [peri; calibration_factor*sum(sum(bwperim(gray1)))];
        xp = [xp; calibration_factor*(cord_of_sprayxpos(gray1))];
        xn = [xn; calibration_factor*(cord_of_sprayxneg(gray1))];
        yp = [yp; calibration_factor*(cord_of_sprayypos(gray1))];
        yn = [yn; calibration_factor*(cord_of_sprayyneg(gray1))];
        
        se = strel('disk',15);
        im1 = uint8(50 * gray1);
        thisimage = strcat('processed_BW_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory1, thisimage);  %name file relative to that directory
        imwrite(((255-10*gray3)-im1), fulldestination); 
        
        thisimage = strcat('processed_contour_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory2, thisimage);  %name file relative to that directory
        rgbImage = ind2rgb(4*imclose(gray3-10,se),turbo);
        imwrite(rgbImage, fulldestination); 

        thisimage = strcat('processed_edge_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory3, thisimage);  %name file relative to that directory
        ime = img;
        BW3 = imdilate((BWfinal), strel('disk',1));
        ime(:,:,1) = 255*BW3;
        imwrite(ime, fulldestination); 
    end
    area_speed = (area(2:end)-area(1:end-1))/frame_rate;
    peri_speed = (peri(2:end)-peri(1:end-1))/frame_rate;
    speedxp = (xp(2:end)-xp(1:end-1))/frame_rate; 
    speedxn = (xn(2:end)-xn(1:end-1))/frame_rate;
    speedyp = (yp(2:end)-yp(1:end-1))/frame_rate;
    speedyn = (yn(2:end)-yn(1:end-1))/frame_rate;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Writing data in excel sheets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    w= xp-xn;
    tavg(:,rem(index,3)+1) = t(1:30);
    areaavg(:,rem(index,3)+1) = area(1:30);
    area_speedavg(:,rem(index,3)+1) = area_speed(1:30);
    periavg(:,rem(index,3)+1) =peri(1:30);
    peri_speedavg(:,rem(index,3)+1) = peri_speed(1:30);
    ypavg(:,rem(index,3)+1) =yp(1:30);
    speedypavg(:,rem(index,3)+1) = speedyp(1:30);
    wavg(:,rem(index,3)+1) = w(1:30);

    Results_Names={'Area','Perimeter','Perimeter speed','Area speed','wave front displacement(along axis)','axial speed','width of spray','time(milliseconds)'};
    if rem(index,3) == 1
        xlswrite(string(xcl),Results_Names(8),sheet,'A1');
        xlswrite(string(xcl),Results_Names(1),sheet,'B1');
        xlswrite(string(xcl),Results_Names(2),sheet,'C1');
        xlswrite(string(xcl),Results_Names(3),sheet,'D1');
        xlswrite(string(xcl),Results_Names(4),sheet,'E1');
        xlswrite(string(xcl),Results_Names(5),sheet,'F1');
        xlswrite(string(xcl),Results_Names(6),sheet,'G1');
        xlswrite(string(xcl),Results_Names(7),sheet,'H1');
        
        xlswrite(string(xcl),t,sheet,string(cola(1)));
        xlswrite(string(xcl),area,sheet,string(cola(2)));
        xlswrite(string(xcl),peri,sheet,string(cola(3)));
        xlswrite(string(xcl),peri_speed,sheet,string(cola(4)));
        xlswrite(string(xcl),area_speed,sheet,string(cola(5)));
        xlswrite(string(xcl),yp,sheet,string(cola(6)));
        xlswrite(string(xcl),speedyp,sheet,string(cola(7)));
        xlswrite(string(xcl),(xp-xn),sheet,string(cola(8)));
    end
    if rem(index,3) == 2
        xlswrite(string(xcl),Results_Names(8),sheet,'J1');
        xlswrite(string(xcl),Results_Names(1),sheet,'K1');
        xlswrite(string(xcl),Results_Names(2),sheet,'L1');
        xlswrite(string(xcl),Results_Names(3),sheet,'M1');
        xlswrite(string(xcl),Results_Names(4),sheet,'N1');
        xlswrite(string(xcl),Results_Names(5),sheet,'O1');
        xlswrite(string(xcl),Results_Names(6),sheet,'P1');
        xlswrite(string(xcl),Results_Names(7),sheet,'Q1');
        
        xlswrite(string(xcl),t,sheet,string(cola2(1)));
        xlswrite(string(xcl),area,sheet,string(cola2(2)));
        xlswrite(string(xcl),peri,sheet,string(cola2(3)));
        xlswrite(string(xcl),peri_speed,sheet,string(cola2(4)));
        xlswrite(string(xcl),area_speed,sheet,string(cola2(5)));
        xlswrite(string(xcl),yp,sheet,string(cola2(6)));
        xlswrite(string(xcl),speedyp,sheet,string(cola2(7)));
        xlswrite(string(xcl),(xp-xn),sheet,string(cola2(8)));
    end
    if rem(index,3) == 0
        xlswrite(string(xcl),Results_Names(8),sheet,'S1');
        xlswrite(string(xcl),Results_Names(1),sheet,'T1');
        xlswrite(string(xcl),Results_Names(2),sheet,'U1');
        xlswrite(string(xcl),Results_Names(3),sheet,'V1');
        xlswrite(string(xcl),Results_Names(4),sheet,'W1');
        xlswrite(string(xcl),Results_Names(5),sheet,'X1');
        xlswrite(string(xcl),Results_Names(6),sheet,'Y1');
        xlswrite(string(xcl),Results_Names(7),sheet,'Z1');
        
        xlswrite(string(xcl),t,sheet,string(cola3(1)));
        xlswrite(string(xcl),area,sheet,string(cola3(2)));
        xlswrite(string(xcl),peri,sheet,string(cola3(3)));
        xlswrite(string(xcl),peri_speed,sheet,string(cola3(4)));
        xlswrite(string(xcl),area_speed,sheet,string(cola3(5)));
        xlswrite(string(xcl),yp,sheet,string(cola3(6)));
        xlswrite(string(xcl),speedyp,sheet,string(cola3(7)));
        xlswrite(string(xcl),(xp-xn),sheet,string(cola3(8)));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reporting ptogress %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    fprintf("%s folder data analysis completed. (%d/%d)\n",string(subFolderNames(index)),index,l2);
    if rem(index,3)==0
        xlswrite(string(xcl),Results_Names(8),sheet,'AB1');
        xlswrite(string(xcl),Results_Names(1),sheet,'AD1');
        xlswrite(string(xcl),Results_Names(4),sheet,'AF1');
        xlswrite(string(xcl),Results_Names(2),sheet,'AH1');
        xlswrite(string(xcl),Results_Names(3),sheet,'AJ1');
        xlswrite(string(xcl),Results_Names(5),sheet,'AL1');
        xlswrite(string(xcl),Results_Names(6),sheet,'AN1');
        xlswrite(string(xcl),Results_Names(7),sheet,'AP1');
        
        xlswrite(string(xcl),mean(tavg')',sheet,string(cola4(1)));
        xlswrite(string(xcl),std(tavg,0,2),sheet,string(cola4(2)));
        xlswrite(string(xcl),mean(areaavg')',sheet,string(cola4(3)));
        xlswrite(string(xcl),std(areaavg,0,2),sheet,string(cola4(4)));
        xlswrite(string(xcl),mean(area_speedavg')',sheet,string(cola4(5)));
        xlswrite(string(xcl),std(area_speedavg,0,2),sheet,string(cola4(6)));
        xlswrite(string(xcl),mean(periavg')',sheet,string(cola4(7)));
        xlswrite(string(xcl),std(periavg,0,2),sheet,string(cola4(8)));
        xlswrite(string(xcl),mean(peri_speedavg')',sheet,string(cola4(9)));
        xlswrite(string(xcl),std(peri_speedavg,0,2),sheet,string(cola4(10)));
        xlswrite(string(xcl),mean(ypavg')',sheet,string(cola4(11)));
        xlswrite(string(xcl),std(ypavg,0,2),sheet,string(cola4(12)));
        xlswrite(string(xcl),mean(speedypavg')',sheet,string(cola4(13)));
        xlswrite(string(xcl),std(speedypavg,0,2),sheet,string(cola4(14)));
        xlswrite(string(xcl),mean(wavg')',sheet,string(cola4(15)));
        xlswrite(string(xcl),std(wavg,0,2),sheet,string(cola4(16)));

        disp("........................sheet completed........................")
    end
end
disp("................................................")
disp("Data analysis completed.")
disp("................................................")
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cord. of spray front function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = cord_of_sprayxpos(img1)
    [~, columns] = find(img1);
    a = max(columns);
end

function a = cord_of_sprayypos(img1)
    [rows, ~] = find(img1);
    a = max(rows);
end

function a = cord_of_sprayxneg(img1)
    [~, columns] = find(img1);
    a = min(columns);
end

function a = cord_of_sprayyneg(img1)
    [rows, ~] = find(img1);
    a = min(rows);
end