fclose(instrfind);            %close all communication interface objects
COM = 'COM4';                 %port 'COM4' is the port for communication
bridge = serial(COM);         %constructs a serial port object with 'COM4'
bridge.InputBufferSize = 100000; %set the buffer size to 100kb in case of overflow 
bridge.Timeout = 5;             %set a timeout of 5 second 
set(bridge,'Terminator','.');   %fgets will stop when receiving the terminator
set(bridge, 'BaudRate', 460800);% set the baudrate
if ~strcmp(bridge.status,'open'),
    fopen(bridge);              % fopen enables the communication
end
    fwrite(bridge, 'ST');
    rows = 144;
    cols = 32;
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
    
for i = 1:rows          
    for j = 1:cols
            for offset = 1:4    
                switch string((j-1)*4+(i-1)*cols*4+offset+2)
                    case 'A'
                        result = result + 10 * 16^(4-offset);
                    case 'B'
                        result = result + 11 * 16^(4-offset);
                    case 'C'
                        result = result + 12 * 16^(4-offset);
                    case 'D'
                        result = result + 13 * 16^(4-offset);
                    case 'E'
                        result = result + 14 * 16^(4-offset);
                    case 'F'
                        result = result + 15 * 16^(4-offset);
                    case '0'
                        result = result;
                    case '1'
                        result = result + 1 * 16^(4-offset);
                    case '2'
                        result = result + 2 * 16^(4-offset);
                    case '3'
                        result = result + 3 * 16^(4-offset);
                    case '4'
                        result = result + 4 * 16^(4-offset);
                    case '5'
                        result = result + 5 * 16^(4-offset);
                    case '6'
                        result = result + 6 * 16^(4-offset);
                    case '7'
                        result = result + 7 * 16^(4-offset);
                    case '8'
                        result = result + 8 * 16^(4-offset);
                    case '9'
                        result = result + 9 * 16^(4-offset);
                    otherwise
                        disp(string(rows*(j-1)*4+(i-1)*4+offset+2))
                end
            end
        	ro_results(i, j) = result*100/1000;
            result = 0;
        end
    end

