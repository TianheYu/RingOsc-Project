fclose(instrfind);            %close all communication interface objects
COM = 'COM5';                 %port 'COM4' is the port for communication
bridge = serial(COM);         %constructs a serial port object with 'COM4'
bridge.InputBufferSize = 1000000; %set the buffer size to 1000kb in case of overflow 
bridge.Timeout = 200;             %set a timeout of 200 second 
set(bridge,'Terminator','.');   %fgets will stop when receiving the terminator
set(bridge, 'BaudRate', 115200);% set the baudrate 115200
if ~strcmp(bridge.status,'open'),
    fopen(bridge);              % fopen enables the communication
end

    newline = sprintf('\n');

    string = fgets(bridge); %what will you get from bridge, what format expected>?
    disp(string);
    result = 0;
    ro_results = zeros(rows, cols);
    if ~(strcmp(string(1), 'T')&& strcmp(string(2), 'H'))
          disp('Warning - incorrect result format')
          continue
    else
          disp('correct')
    end        
    LENGTH = 6;		% the length of the incoming data
    TEST_COUNT = 10;	% the number of tests operated
    rows = 27;		% the number of rows
    cols = 26;		% the number of columns
    P_r = 10^5;		% 记上升沿的周期个数
     for count = 1:TEST_COUNT
        for i = 1:rows          
            for j = 1:cols
                    for offset = 1:LENGTH    
                        switch string((j-1)*LENGTH+(i-1)*cols*LENGTH+offset+count*rows*cols*LENGTH+1+count)                
                            case '0'
                                result = result;
                            case '1'
                                result = result + 1 * 10^(LENGTH-offset);
                            case '2'
                                result = result + 2 * 10^(LENGTH-offset);
                            case '3'
                                result = result + 3 * 10^(LENGTH-offset);
                            case '4'
                                result = result + 4 * 10^(LENGTH-offset);
                            case '5'
                                result = result + 5 * 10^(LENGTH-offset);
                            case '6'
                                result = result + 6 * 10^(LENGTH-offset);
                            case '7'
                                result = result + 7 * 10^(LENGTH-offset);
                            case '8'
                                result = result + 8 * 10^(LENGTH-offset);
                            case '9'
                                result = result + 9 * 10^(LENGTH-offset);
                            otherwise
                                disp(string((j-1)*LENGTH+(i-1)*cols*LENGTH+offset+2))
                        end
                    end
                    ro_results(i, j,count) = result/P_r*50; %将接收数据变为频率，单位MHz
                    result = 0;
            end
        end
     end 
	ro_results= ro_results([1:4,6:13,15:22,24:27],:,:);		%%将第5、14、23行数据删除
	mixed_M&Lslices_data = ro_results(:,[1:4,21:23],:);		%在混合m和lslice上环阵数据
	Lslice_data = ro_results(:,[5,7,13,15,17,19,24,25],:);		%仅在Lslice上环阵数据
	Mslice_data = ro_results(:,[6,8,9,10,11,12,14,16,18,20,26],:);	%仅在Mslice上环阵数据
	%imagesc函数可以清晰的看到整体频率变化


