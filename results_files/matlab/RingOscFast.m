function ro_results = RingOscFast(bridge)
    flushinput(bridge);
    fwrite(bridge, 'ST');
    rows = 144;%22;
    cols = 32;%28;
    newline = sprintf('\n');

    string = fgets(bridge); %what will you get from bridge, what format expected>?
    disp(string);
    result = 0;
    ro_results = zeros(rows, cols);
    if ~(strcmp(string(1), 'T')&& strcmp(string(2), 'H'))
          disp('Warning - incorrect result format')
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
                        reslut = result;
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
        	ro_results(i, j) = result/10;
            result = 0;
        end
    end
