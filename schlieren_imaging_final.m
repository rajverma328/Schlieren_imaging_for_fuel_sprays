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

cola = {'A2' 'B2' 'C2' 'D2' 'E2' 'F2' 'G2' 'H2' 'I2'};
cola2 = {'K2' 'L2' 'M2' 'N2' 'O2' 'P2' 'Q2' 'R2' 'S2'};
cola3 = {'U2' 'V2' 'W2' 'X2' 'Y2' 'Z2' 'AA2' 'AB2' 'AC2'};
cola4 = {'AE2' 'AF2' 'AG2' 'AH2' 'AI2' 'AJ2' 'AK2' 'AL2' 'AM2' 'AN2' 'AO2' 'AP2' 'AQ2' 'AR2' 'AS2' 'AT2' 'AU2' 'AV2'};

colah = {'A1' 'B1' 'C1' 'D1' 'E1' 'F1' 'G1' 'H1' 'I1'};
cola2h = {'K1' 'L1' 'M1' 'N1' 'O1' 'P1' 'Q1' 'R1' 'S1'};
cola3h = {'U1' 'V1' 'W1' 'X1' 'Y1' 'Z1' 'AA1' 'AB1' 'AC1'};
cola4h = {'AE1' 'AF1' 'AG1' 'AH1' 'AI1' 'AJ1' 'AK1' 'AL1' 'AM1' 'AN1' 'AO1' 'AP1' 'AQ1' 'AR1' 'AS1' 'AT1' 'AU1' 'AV1'};

col_count = 1;
xcl = strcat(data_filename,'\results_test_29Aug.xlsx'); 
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
    CA = [];

    for cnt = 1:l %replace by l to iterate 
        img = imread(fullfile(path,tif_files(cnt).name));
        r = centerCropWindow2d(size(img),targetSize);
        img = imcrop(img,r);
        gray2 = rgb2gray(img);
        gray3 = bg_img1-gray2; 
        gray1 = medfilt2(gray3);
        gray1 = gray1>rcor;
        gray1 = medfilt2(gray1);
        se = strel('diamond',10);
        gray1 = medfilt2(gray1);
        se1 = strel('disk',10);
        gray1 = imclose(gray1,se);
        gray1 = imclose(gray1,se1);
        gray1 = imfill(gray1,"holes");

        % gray1 = bwconvhull(gray1);

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
        top_pixel = cord_of_sprayxneg(gray1);

        %%%%%%%%%%%%%%%%% L/3 taken %%%%%%%%%%%%%%%%% 
        sample_pixel = floor((top_pixel +  (cord_of_sprayypos(gray1)-top_pixel)/3));  
        %%%%%%%%%%%%%%%%% ......... %%%%%%%%%%%%%%%%%
        
        trp = find(gray1(top_pixel,:),1,'last');
        lrp = find(gray1(sample_pixel,:),1,'last');
        CA = [CA; atand((lrp-trp)/(sample_pixel-top_pixel))];
        
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
    CAavg(:,rem(index,3)+1) = CA(1:30);

    Results_Names={'time(milliseconds)','Area','Perimeter','Perimeter speed','Area speed','wave front displacement(along axis)','axial speed','width of spray','Cone Angle'};
    Results_Names_average={'Average time(milliseconds)','Average Area','Average Perimeter','Average Perimeter speed','Average Area speed','Average wave front displacement(along axis)','Average axial speed','Average width of spray','Average Cone Angle'};
    Results_Names_std={'std time(milliseconds)','std Area','std Perimeter','std Perimeter speed','std Area speed','std wave front displacement(along axis)','std axial speed','std width of spray','std Cone Angle'};
    
    Result_table = NaN(500,9);
    Result_table(1:length(t),1) = t;
    Result_table(1:length(area),2) = area;
    Result_table(1:length(peri),3) = peri;
    Result_table(1:length(peri_speed),4) = peri_speed;
    Result_table(1:length(area_speed),5) = area_speed;
    Result_table(1:length(yp),6) = yp;
    Result_table(1:length(speedyp),7) = speedyp;
    Result_table(1:length((xp-xn)),8) = (xp-xn);
    Result_table(1:length(CA),9) = CA;

    if rem(index,3) == 1
        for i = 1:length(Results_Names)
            xlswrite(string(xcl),Results_Names(i),sheet, cell2mat(colah(i)));
        end
        for i = 1:length(Results_Names)
            xlswrite(string(xcl),Result_table(:,i),sheet,string(cell2mat(cola(i))));
        end
    end
    if rem(index,3) == 2
        for i = 1:length(Results_Names)
            xlswrite(string(xcl),Results_Names(i),sheet, cell2mat(cola2h(i)));
        end
        for i = 1:length(Results_Names)
            xlswrite(string(xcl),Result_table(:,i),sheet,string(cell2mat(cola2(i))));
        end
    end
    if rem(index,3) == 0
        for i = 1:length(Results_Names)
            xlswrite(string(xcl),Results_Names(i),sheet, cell2mat(cola3h(i)));
        end
        for i = 1:length(Results_Names)
            xlswrite(string(xcl),Result_table(:,i),sheet,string(cell2mat(cola3(i))));
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reporting ptogress %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    fprintf("%s folder data analysis completed. (%d/%d)\n",string(subFolderNames(index)),index,l2);
    if rem(index,3)==0
        i = 1;
        while i < length(Results_Names)
            xlswrite(string(xcl),Results_Names_average(i),sheet, cell2mat(cola4h(i)));
            xlswrite(string(xcl),Results_Names_std(i),sheet, cell2mat(cola4h(i+1)));
            i = i+2;
        end
        
        xlswrite(string(xcl),mean(tavg')',sheet,string(cell2mat(cola4h(1))));
        xlswrite(string(xcl),std(tavg,0,2),sheet,string(cell2mat(cola4h(2))));
        xlswrite(string(xcl),mean(areaavg')',sheet,string(cell2mat(cola4h(3))));
        xlswrite(string(xcl),std(areaavg,0,2),sheet,string(cell2mat(cola4h(4))));
        xlswrite(string(xcl),mean(area_speedavg')',sheet,string(cell2mat(cola4h(5))));
        xlswrite(string(xcl),std(area_speedavg,0,2),sheet,string(cell2mat(cola4h(6))));
        xlswrite(string(xcl),mean(periavg')',sheet,string(cell2mat(cola4h(7))));
        xlswrite(string(xcl),std(periavg,0,2),sheet,string(cell2mat(cola4h(8))));
        xlswrite(string(xcl),mean(peri_speedavg')',sheet,string(cell2mat(cola4h(9))));
        xlswrite(string(xcl),std(peri_speedavg,0,2),sheet,string(cell2mat(cola4h(10))));
        xlswrite(string(xcl),mean(ypavg')',sheet,string(cell2mat(cola4h(11))));
        xlswrite(string(xcl),std(ypavg,0,2),sheet,string(cell2mat(cola4h(12))));
        xlswrite(string(xcl),mean(speedypavg')',sheet,string(cell2mat(cola4h(13))));
        xlswrite(string(xcl),std(speedypavg,0,2),sheet,string(cell2mat(cola4h(14))));
        xlswrite(string(xcl),mean(wavg')',sheet,string(cell2mat(cola4h(15))));
        xlswrite(string(xcl),std(wavg,0,2),sheet,string(cell2mat(cola4h(16))));
        xlswrite(string(xcl),mean(CAavg')',sheet,string(cell2mat(cola4h(17)))); %% The Cone Angle implementation
        xlswrite(string(xcl),std(CAavg,0,2),sheet,string(cell2mat(cola4h(18))));

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