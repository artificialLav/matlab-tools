classdef nwkConverter

    properties

    end

    methods (Static)
        function [nwk] = stl2nwk(filePath);
            [nwk.ptCoordMx, nwk.faceMx3, nwk.np, nwk.nf, nwk.dia] = stl2nwk(filePath);
        end

        function [nwk] = mesh2nwk(filePath);
            [nwk.ptCoordMx, nwk.faceMx] = mesh2nwk(filePath);
        end

        function nwk2nwkx(filePath);
            nwk2nwkx(filePath);
        end
    end
end

function [ptCoordMx, faceMx3, np, nf, dia] = stl2nwk(filePath)

        [TR, ~, ~, ~] = stlread(filePath);

        ptCoordMx = TR.Points;
        np = length(ptCoordMx(:,1));

        faceMx3 = TR.ConnectivityList;
        nf = length(faceMx3(:,1));

        dia = [];

end

function [ptCoordMx, faceMx] = mesh2nwk(filePath)    

    fid = fopen(filePath, 'r');
    if fid == -1
        error('Could not open the Gambit mesh file.');
    end

    ptCoordMx = [];
    faceMx = [];

    [~, fileName, ~] = fileparts(filePath);
    pMxFile = strcat(fileName, '.pMx');
    ptFid = fopen(pMxFile, 'w');

    fMxFile = strcat(fileName, '.fMx');
    faceFid = fopen(fMxFile, 'w');

    while ~feof(fid)
        line = fgetl(fid);

        if contains(line, '(10 (0 ')
            line = fgetl(fid);
            np = sscanf(line, '(10 (0 %*x %x %*x %*x)');

            lines_cell = textscan(fid, '%s', np, 'Delimiter', '\n');
            lines_str = string(lines_cell{1});
            fprintf(ptFid, '%s\n', lines_str);
            fclose(ptFid);
        end
        
        line = fgetl(fid);
        
        if contains(line, '(13 (0 ')
            % Extract the range of face indices in the entire mesh
            range = sscanf(line, '(13 (0 %x %x %*x)');
            numFaces = range(2) - range(1) + 1;
            groupId = 0;

            while ~feof(fid)
                line = fgetl(fid);
                if contains(line, '(13 (')
                    groupId = groupId + 1;

                    % Extract the range of face indices in the current group
                    groupRange = sscanf(line, '(13 (%*x %x %x %*x)');
                    groupNumFaces = groupRange(2) - groupRange(1) + 1;

                    % Read the face data for the current group
                    for i = 1:groupNumFaces
                        line = fgetl(fid);
                        faceData = sscanf(line, '%x %x %x %x %*x');

                        if faceData(1) == 2
                            fprintf(faceFid, '%d %d %d\n', groupCounter, faceData(2), faceData(3));
                        elseif faceData(1) == 3
                            fprintf(faceFid, '%d %d %d %d\n', groupCounter, faceData(2), faceData(3), faceData(4));
                        end
                    end
                end
                fclose(faceFid);
            end
         end       

        % starts at )) and faces line, convert to fMx
        % check the pdf for multiple formats
        % remove the last blank line in .pMx file
        
     end


end
