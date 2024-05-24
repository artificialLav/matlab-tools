function drawingTool()
    

%%%%%%%%%%%%%%%%%%%%%% Figure, axes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Create a figure and axes for drawing in 2D planes
    % Create a single figure with two subplots
    fig = figure("Position", [50 50 1350 750]);
    
    % Create axes for the first subplot (2D drawing)
    axDraw = subplot(1, 2, 1);
    set(gcf,'Pointer','crosshair');
    grid(axDraw, 'on');
    title(axDraw, 'Drawing Tool - 2D View');
    xlabel(axDraw, 'X-axis');
    ylabel(axDraw, 'Y-axis');
    zlabel(axDraw, 'Z-axis');
    axisLimits = [-10, 10]; % Default axis limits
    xlim(axDraw, axisLimits);
    ylim(axDraw, axisLimits);
    zlim(axDraw, axisLimits);
    
    % Create axes for the second subplot (3D view)
    axView = subplot(1, 2, 2);
    grid(axView, 'on');
    title(axView, '3D View');
    xlabel(axView, 'X-axis');
    ylabel(axView, 'Y-axis');
    zlabel(axView, 'Z-axis');
    xlim(axView, axisLimits);
    ylim(axView, axisLimits);
    zlim(axView, axisLimits);
    view(axView, 3);
   
    % Adjust subplot positions
    axDraw.Position = [0.05, 0.2, 0.40, 0.75];
    axView.Position = [0.55, 0.2, 0.40, 0.75];

%%%%%%%%%%%%%%%%%%%%%%%%%%%% UI options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%    


    % UI buttons for toggle, save options
    toggleBtn = uicontrol(fig, 'Style', 'togglebutton', 'String', 'Y-Z plane', ...
       'Position', [20, 20, 70, 30], 'Callback', @toggleAxesCb);

    loadNwkBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Load nwk', ...
       'Position', [100, 55, 70, 30], 'Callback', @loadNwkFileCb);
    saveNwkBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Save nwk', ...
       'Position', [100, 20, 70, 30], 'Callback', @saveNwkCb);

    connectBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Connect', ...
        'Position', [175, 20, 90, 30], 'Callback', @connectPointsCb);
    autoConnectBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Auto Connect', ...
        'Position', [175, 55, 90, 30], 'Callback', @autoConnectCb);

    clearBtn =  uicontrol(fig, 'Style', 'pushbutton', 'String', 'Clear', ...
        'Position', [460, 55, 80, 30], 'Callback', @clearCb);
    deletePtsBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Delete Pts', ...
        'Position', [270, 20, 80, 30], 'Callback', @deletePtsCb);

    loadToViewBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'View Only Load',...
        'Position', [355, 20, 100, 30], 'Callback', @loadToViewCb);
    clearObjBtn = uicontrol(fig, 'Style', 'pushbutton', 'String','Clear Objects', ...
        'Position', [460, 20, 80, 30], 'Callback', @clearObjCb);
    hideObjBtn = uicontrol('Style', 'pushbutton', 'String', 'Hide Objects', ...
        'Position', [355, 55, 100, 30], 'Callback', @hideObjCb);
    editPtsBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Edit Pts', ...
        'Position', [270, 55, 80, 30], 'Callback', @editPtsCb);

    coordEditBoxLabel = uicontrol(fig, 'Style', 'text', 'String', 'Z:', ...
    'Position', [545, 20, 15, 30], 'HorizontalAlignment', 'left', 'FontSize', 14);
    coordEditBox = uicontrol(fig, 'Style', 'edit', 'String', '0', ...
    'Position', [565, 20, 40, 30], 'Callback', @updateThirdCoord);

     thicknessLabel = uicontrol(fig, 'Style', 'text', 'String', 'Thickness:', ...
    'Position', [615, 20, 70, 30], 'HorizontalAlignment', 'left', 'FontSize', 14);
     thicknessBox = uicontrol(fig, 'Style', 'edit', 'String', '1', ...
    'Position', [690, 20, 40, 30], 'Callback', @updateThirdCoord);


    showText = annotation(fig, 'textbox', [0.02, 0.12, 0.45, 0.03], 'String', '',...
        'HorizontalAlignment', 'left', 'EdgeColor', 'none', 'FontSize', 10);


%%%%%%%%%%%%%%%%%% Global variable initialisations %%%%%%%%%%%%%%%%%%%%%%    


    % Store points and handles for points in Draw and View axes
    ptCoordMx = [];
    faceMx = [];
    connectIndices = [];
 
    G = graph();
    global plotObjDraw;
    global plotObjView;
    global np;
    np = 0;

    % Current third coordinate value, set to default value 0
    currentThirdCoord = 0;
    thickness = 1;
    zlim(axDraw, [-thickness, 0]);

    % Define the states for the toggle button
    toggleStates = {'XY', 'YZ', 'XZ'};
    currentState = 1; % Initial state: X-Y axes

    % Flag to indicate whether connect mode is active
    autoConnectMode = false;

    % Flag to indicate whether auto-connect mode is active
    connectMode = false;

    % Flag to indicate whether delete mode is active
    deleteMode = false;

    % Flag to indicate whether edit mode is active
    editMode = false;

    % Table to store all the loaded objects
    rendererTable = table('Size', [0, 4], ...
                   'VariableTypes', {'string', 'string', 'cell', 'cell'}, ...
                   'VariableNames', {'fileName', 'type', 'drawHandle', 'viewHandle'});

    % Add callback function for mouse click on axes
    axDraw.ButtonDownFcn = @addPoint;

    % Button handles
    btnHandles = [connectBtn, autoConnectBtn, deletePtsBtn, editPtsBtn];
    % Initialize button states (0: inactive, 1: active)
    btnStates = zeros(1, numel(btnHandles));

    % Initial state is to show the BMP
    showObj = true; 

    % Initialise the 2D drawing plane
    hold(axView, "on");
    drawPlane = surf([], [], [], 'FaceColor', 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.05);
    updateDrawPlane(axView, currentThirdCoord);
    hold(axView, "off");

    % Add callback function for mouse click on 2D drawing plane
    set(drawPlane, 'ButtonDownFcn', @selectPlane);


%%%%%%%%%%%%%%%%%%%%%%%% UI Callback functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % Callback function to add a new point
    function addPoint(~, ~)
        % Store original axes limits
        xlimOriginal = xlim(axDraw);
        ylimOriginal = ylim(axDraw);
        zlimOriginal = zlim(axDraw);
  
        % Get current point coordinates
        currPoint = axDraw.CurrentPoint(1, 1:3);
        x = currPoint(1, 1);
        y = currPoint(1, 2);
        z = currPoint(1, 3);

        % Initialise the third coordinate of a 2D plane to 0
        switch toggleStates{currentState}
            case 'XY'
                z = currentThirdCoord;
            case 'YZ'
                x = currentThirdCoord;
            case 'XZ'
                y = currentThirdCoord;
        end

        G = addnode(G, 1);
        np = np + 1;
        G.Nodes{np, {'X', 'Y', 'Z'}} = [x, y, z];

        % Replot the graph on both axes
        rePlotGraph();

        showTextOnFig(['New point added: (', num2str(x), ', ', num2str(y), ', ', num2str(z), ')']);

        % Restore original axes limits
        xlim(axDraw, xlimOriginal);
        ylim(axDraw, ylimOriginal);
        zlim(axDraw, zlimOriginal);
    end


    % Callback function to start dragging the point
    function startDragging(~, event)

        % Get the coordinates of the selected point from the event
        clickPoint = event.IntersectionPoint(1:3);

        % Find the index of the selected point in the graph structure G
        idx = findNearestPoint(clickPoint);

        % Create a temporary mask point
        hold(axDraw, "on");
        maskPoint = scatter3(axDraw, clickPoint(1), clickPoint(2), clickPoint(3), 100, [1 0.5 0], 'filled');
        hold(axDraw, "off");
    
        % Set the callback function for mouse movement
        set(fig, 'WindowButtonMotionFcn', {@dragging, maskPoint, idx});

        % Set the callback function for mouse release
        set(fig, 'WindowButtonUpFcn', {@stopDragging, maskPoint, idx});
    end

    % Callback function for dragging the point
    function dragging(~, ~, maskPoint, idx)
        % Get current point coordinates
        currPoint = get(axDraw, 'CurrentPoint');
        x = currPoint(1, 1);
        y = currPoint(1, 2);
        z = currPoint(1, 3);

        if idx 
            % Do not alter the third coordinate while moving the point in 2D planes
            switch toggleStates{currentState}
                case 'XY'
                    z = G.Nodes.Z(idx);
                case 'YZ'
                    x = G.Nodes.X(idx);
                case 'XZ'
                    y = G.Nodes.Y(idx);
            end
    
            % Update the position of the mask point
            set(maskPoint, 'XData', x, 'YData', y, 'ZData', z);
        end

    end

    % Callback function once the point dragging has stopped.
    function stopDragging(~, ~, maskPoint, idx)

        % Get the final position of the mask point
        x = maskPoint.XData;
        y = maskPoint.YData;
        z = maskPoint.ZData;

        if idx
            switch toggleStates{currentState}
                case 'XY'
                    z = G.Nodes.Z(idx);
                case 'YZ'
                    x = G.Nodes.X(idx);
                case 'XZ'
                    y = G.Nodes.Y(idx);
            end
            
            % Update the coordinates of the selected point in G.Nodes
            G.Nodes{idx, {'X', 'Y', 'Z'}} = [x y z];
        
            % Replot the graph on both axes
            rePlotGraph();

        end

        % Clear the mask point
        delete(maskPoint);

        % Remove the callback functions for mouse movement and release
        set(fig, 'WindowButtonMotionFcn', '');
        set(fig, 'WindowButtonUpFcn', '');
    end

    % Callback function to toggle between X-Y, Y-Z, and X-Z planes
    function toggleAxesCb(~, ~)
        % Set the next state in the toggleStates list 
        currentState = mod(currentState, length(toggleStates)) + 1;

        coordEditBox.String = '0';
        thicknessBox.String = '1';
        thirdAxisLimits = [- thickness, 0];
        
        % Change the axes based on the current state
        switch toggleStates{currentState}
            case 'XY'
                view(axDraw, 0, 90);
                coordEditBoxLabel.String = 'Z:';
                toggleBtn.String = 'Y-Z plane';
                zlim(axDraw, thirdAxisLimits);
                axLim = get(axView, 'YLim');
                ylim(axDraw, axLim);
            case 'YZ'
                view(axDraw, 90, 0);
                coordEditBoxLabel.String = 'X:';
                toggleBtn.String = 'X-Z plane';
                xlim(axDraw, thirdAxisLimits);
                axLim = get(axView, 'ZLim');
                zlim(axDraw, axLim);
            case 'XZ'
                view(axDraw, 0, 0);
                coordEditBoxLabel.String = 'Y:';
                toggleBtn.String = 'X-Y plane';
                ylim(axDraw, thirdAxisLimits);
                axLim = get(axView, 'XLim');
                xlim(axDraw, axLim);
        end
        currentThirdCoord = 0;
        thickness = 1;
        updateDrawPlane(axView, currentThirdCoord);

    end

    % Callback function for the Connect button
    function connectPointsCb(~, ~)
         % Toggle connect mode
         connectMode = ~connectMode;

        if connectMode && np > 0
            showTextOnFig('Connect mode activated. Click two points to connect.');
            set(axDraw, 'ButtonDownFcn', @connectPoints);
            set(plotObjDraw, 'ButtonDownFcn', @connectPoints);
            updateBtnState(1);
        elseif connectMode && np == 0
            connectMode = ~connectMode;
            showTextOnFig('Connect mode not activated. Add points and try again.');
        else
            showTextOnFig('Connect mode deactivated.');
            set(axDraw, 'ButtonDownFcn', @addPoint);
            set(plotObjDraw, 'ButtonDownFcn', @startDragging);
            updateBtnState(1);
        end
    end
    
    % Callback function for mouse click on axes during connect mode
    function connectPoints(~, ~)

        % Get current point coordinates
        currPoint = get(axDraw, 'CurrentPoint');
        x = currPoint(1, 1);
        y = currPoint(1, 2);
        z = currPoint(1, 3);
        
        % Find the nearest point to the clicked location
        switch toggleStates{currentState}
            case 'XY'
                distances = sqrt((G.Nodes.X - x).^2 + (G.Nodes.Y - y).^2);
            case 'YZ'
                distances = sqrt((G.Nodes.Y - y).^2 + (G.Nodes.Z - z).^2);
            case 'XZ'
                distances = sqrt((G.Nodes.X - x).^2 + (G.Nodes.Z - z).^2);
        end

        [~, nearestIdx] = min(distances);
     
        % Add the point index to the list of points to be connected
        connectIndices = [connectIndices, nearestIdx];
            
        % If two points are selected, connect them
        if length(connectIndices) == 2

              % Add an edge between the two selected points in G.Edges
              G = addedge(G, connectIndices(1), connectIndices(2));
              
              rePlotGraph();

              connectIndices = [];
        end

    end

    % Callback function for the 'Auto Connect' button
    function autoConnectCb(~, ~)
        autoConnectMode = ~autoConnectMode;
        if autoConnectMode
            %autoConnectExistingPts(src, event);
            showTextOnFig('Auto-Connect mode activated. Click add new points.');
            set(axDraw, 'ButtonDownFcn', @addConnectedPoint);
        else
            showTextOnFig('Auto-Connect mode deactivated.');
            set(axDraw, 'ButtonDownFcn', @addPoint);
        end
        updateBtnState(2);
    end


    function addConnectedPoint(src, event)
        addPoint(src, event);
        if np > 1
            G = addedge(G, (np - 1), np);
            rePlotGraph();
        end
    end

    function clearCb(~, ~)
        % Empty the graph structure, delete plot objects on axes
        G = graph();
        np = 0;
        delete(plotObjDraw);
        delete(plotObjView);

        % Reset the connect, auto-connect and delete modes
        if autoConnectMode
            autoConnectMode = false;
            disp('Auto-Connect mode is deactivated.');
            updateBtnState(2);
        end

        if connectMode
            connectMode = false;
            disp('Connect mode is deactivated.');
            updateBtnState(1);
        end

        if deleteMode
            deleteMode = false;
            disp('Delete mode is deactivated.');
            updateBtnState(3);

        end

        if editMode
            editMode = false;
            disp('Edit mode is deactivated.');
            updateBtnState(4);
        end

        set(axDraw, 'ButtonDownFcn', @addPoint);

    end

    % Callback function for the "Delete Pts" button
    function deletePtsCb(~, ~)
        deleteMode = ~deleteMode;
        if deleteMode && np > 0

            showTextOnFig('Delete mode activated. Click on a point to delete it.');
            set(plotObjDraw, 'ButtonDownFcn', @deleteFromGraph);
            set(axDraw, 'ButtonDownFcn', @deleteFromGraph);
            updateBtnState(3);

        elseif deleteMode && np == 0

            deleteMode = ~deleteMode;
            showTextOnFig('Delete mode not activated. Add points and try again.');
        
        else
            showTextOnFig('Delete mode deactivated');
            set(plotObjDraw, 'ButtonDownFcn', @startDragging);
            set(axDraw, 'ButtonDownFcn', @addPoint);
            updateBtnState(3);

        end
    end

    function deleteFromGraph(~, event)
        % Get the coordinates of the selected point from the event
        clickPoint = event.IntersectionPoint(1:3);

        % Find the index of the selected point in the graph structure G
        pointIdx = findNearestPoint(clickPoint);

        if pointIdx
            G = rmnode(G, pointIdx);
            np = np - 1;
            rePlotGraph()
        end

    end

    % Callback function for the "Edit Pts" button
    function editPtsCb(~, ~)
        editMode = ~editMode;
        if editMode && np > 0
            showTextOnFig('Edit mode activated. Click on a point to edit its coordinates.');
            set(plotObjDraw, 'ButtonDownFcn', @editPoint);
            set(axDraw, 'ButtonDownFcn', @editPoint);
            updateBtnState(4);

        elseif editMode && np == 0
            editMode = ~editMode;
            showTextOnFig('Edit mode not activated. Add points and try again.');
        else
            showTextOnFig('Edit mode deactivated');
            set(plotObjDraw, 'ButtonDownFcn', @startDragging);
            set(axDraw, 'ButtonDownFcn', @addPoint);
            updateBtnState(4);

        end
    end

    function editPoint(~, event)
        % Get the coordinates of the selected point from the event
        clickPoint = event.IntersectionPoint(1:3);
        
        % Find the index of the selected point in the graph structure G
        pointIdx = findNearestPoint(clickPoint);
        
        if pointIdx
            % Get the existing coordinates of the point
            existingCoords = G.Nodes(pointIdx, :);
            
            % Create a dialog box to edit coordinates
            dlgTitle = 'Edit Coordinates';
            prompt = {'X-coordinate:', 'Y-coordinate:', 'Z-coordinate:'};
            defaultInput = {num2str(existingCoords.X(1)), num2str(existingCoords.Y(1)),...
                num2str(existingCoords.Z(1))};
            dims = [1 50];
            editedCoords = inputdlg(prompt, dlgTitle, dims, defaultInput); %, opts, 'on');
            
            if ~isempty(editedCoords)
                % Update the coordinates of the selected point
                newX = str2num(editedCoords{1});
                newY = str2num(editedCoords{2});
                newZ = str2num(editedCoords{3});
                G.Nodes{pointIdx, {'X', 'Y', 'Z'}} = [newX, newY, newZ];
                
                % Replot the graph
                rePlotGraph();
                expandAxesLimits([newX, newY, newZ]);
            end
        end
    end

    % Callback function to update the third coordinate
    function updateThirdCoord(~, ~)

        currentThirdCoord = str2double(coordEditBox.String);       
        if isnan(currentThirdCoord)
            errordlg('Please enter a valid number for the coordinate.', 'Invalid Input', 'modal');
            coordEditBox.String = '0';
            return;
        end

        thickness = str2double(thicknessBox.String);       
        if isnan(thickness)
            errordlg('Please enter a valid number for the coordinate.', 'Invalid Input', 'modal');
            thicknessBox.String = '1';
            return;
        end

        thirdAxisLimits = [currentThirdCoord - thickness, currentThirdCoord];
        % Make the 2D axis a thin slice in third axis
        switch toggleStates{currentState}
            case 'XY'
                zlim(axDraw, thirdAxisLimits);
            case 'YZ'
                xlim(axDraw, thirdAxisLimits);
            case 'XZ'
                ylim(axDraw, thirdAxisLimits);
        end
        updateDrawPlane(axView, currentThirdCoord);

    end

    function loadNwkFileCb(~, ~)

        [fileName, filePath] = uigetfile('*.fMx', 'Select a face matrix file');
        
        if fileName == 0
            disp('File selection canceled');
            return;
        end
    
        % Open the file
        fileId = fopen(fullfile(filePath, fileName), 'rt');
        if fileId == -1
            error('File cannot be opened: %s', fileName);
        end
 
        showTextOnFig("Loading nwk in process...");

        [~, name, ~] = fileparts(fullfile(filePath, fileName));
        nwk = nwkHelp.load(name);

        if nwk.nf
            nwk.faceMx(:,2) = nwk.faceMx(:,2) + np;
            nwk.faceMx(:,3) = nwk.faceMx(:,3) + np;
        end

        for i = 1:nwk.np
            G = addnode(G, 1);
            np = np + 1;
            G.Nodes{np, {'X', 'Y', 'Z'}} = nwk.ptCoordMx(i, :);
        end

        if nwk.nf
            G = addedge(G, nwk.faceMx(:,2), nwk.faceMx(:,3));
        end

        % Replot the graph on both axes
        rePlotGraph();
        expandAxesLimits(nwk.ptCoordMx);

        showTextOnFig("Loading complete.");

    end

    function loadToViewCb(~, ~)

         [file, path] = uigetfile('*.bmp;*.fMx;*.stl', 'Select a file to load');
         if isequal(file, 0) || isequal(path, 0)
              disp('File selection canceled');
              return
         end

         showTextOnFig("Loading obj in process...");


         [~, ~, ext] = fileparts(fullfile(path, file));

         if strcmp(ext, '.bmp')
               [drawHandle, viewHandle] = loadBmp(path, file);
               file = [file, '(z=', num2str(currentThirdCoord), ')'];
         elseif strcmp(ext, '.fMx')
               [drawHandle, viewHandle] = loadNwkToView(path, file);
         elseif strcmp(ext, '.stl')
               [drawHandle, viewHandle] = loadStl(path, file);
         end
         
         rendererTable = [rendererTable; {file, ext, drawHandle, viewHandle}];

         showTextOnFig("Loading complete.");

    end

    function [drawHandle, viewHandle] = loadNwkToView(path, file)

        [~, name, ~] = fileparts(fullfile(path, file));
        nwk = nwkHelp.load(name);

        GTmp = addnode(G, nwk.np);
        for i = 1:nwk.np
            GTmp.Nodes{i, {'X', 'Y', 'Z'}} = nwk.ptCoordMx(i, :);
        end
        GTmp = addedge(GTmp, nwk.faceMx(:,2), nwk.faceMx(:,3));

        hold(axDraw, 'on');
        drawHandle = plot(axDraw, GTmp, 'XData', GTmp.Nodes.X, 'YData', GTmp.Nodes.Y,...
            'ZData', GTmp.Nodes.Z, 'Marker', 'o', 'NodeColor', [0.4 0.4 0.4],...
            'EdgeColor', [0.4 0.4 0.4]);
       % uistack(drawHandle, 'bottom');
        set(drawHandle, 'HitTest', 'off');
        hold(axDraw, 'off');

        hold(axView, 'on');
        viewHandle = plot(axView, GTmp, 'XData', GTmp.Nodes.X, 'YData', GTmp.Nodes.Y,...
            'ZData', GTmp.Nodes.Z, 'Marker', 'o', 'NodeColor', [0.4 0.4 0.4], 'EdgeColor', [0.4 0.4 0.4]);
        hold(axView, 'off');

        expandAxesLimits(nwk.ptCoordMx);

    end

    function [hImage2D, hImage3D] = loadBmp(path, file)
         if ~strcmp(toggleStates{currentState}, 'XY')
             showTextOnFig('Please switch to the X-Y plane and try adding the image again.');
             return 
         end

         img = imread(fullfile(path, file));

         [imgHeight, imgWidth, ~] = size(img);
         xLimits = xlim(axDraw);
         yLimits = ylim(axDraw);
         zCoord = currentThirdCoord;
         xNormalized = linspace(xLimits(1), xLimits(2), imgWidth);
         yNormalized = linspace(yLimits(1), yLimits(2), imgHeight);

         [x, y] = meshgrid(xNormalized, yNormalized);
         hold(axView, "on");
         hImage3D = surf(axView, x, y, zCoord * ones(size(x)), img,...
             'FaceColor', 'texturemap', 'EdgeColor', 'none');
         hold(axView, "off");

         hold(axDraw, "on");
         hImage2D = surf(axDraw, [xLimits(1), xLimits(2)], [yLimits(1), yLimits(2)], zCoord * ones(2),...
             'CData', img, 'FaceColor', 'texturemap', 'EdgeColor', 'none', 'FaceAlpha', 1.0);
         uistack(hImage2D, 'bottom');
         set(hImage2D, 'HitTest', 'off');
         view(axDraw, 2);
         grid(axDraw, 'on');
         hold(axDraw, "off");

    end

    function [drawHandle, viewHandle] = loadStl(path, file)

        [TR, ~, ~, ~] = stlread(fullfile(path, file));
        points = TR.Points;
        faces = TR.ConnectivityList;

        hold(axDraw, "on");
        drawHandle = patch(axDraw, 'Faces', faces, 'Vertices', points, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', '[0.75 0.75 0.75]');
        set(drawHandle, 'HitTest', 'off');
        view(axDraw, 2);
        hold(axDraw, "off");

        hold(axView, "on");
        viewHandle = patch(axView, 'Faces', faces, 'Vertices', points, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', '[0.75 0.75 0.75]');
        hold(axView, "off");

        expandAxesLimits(points);

    end

    % Callback function to clear Bmp, Nwk, Stl objects
    function clearObjCb(~, ~)
        objNames = rendererTable.fileName;
        
        % Create a dialog box with dropdown menu
        [selection, ok] = listdlg('ListString', objNames, 'SelectionMode', 'single',...
            'PromptString', 'Select an object to clear:', 'Name', 'Select Object', 'ListSize', [300, 100]);        
        
        if ok
            delete(rendererTable.drawHandle(selection));
            delete(rendererTable.viewHandle(selection));
            rendererTable(selection, :) = [];
            rendererTable(any(ismissing(rendererTable), 2), :) = [];
        end

    end
    
    % Callback function to save the points to a file
    function saveNwkCb(~, ~)
        % Check if G.Edges and G.Nodes are not empty
        if isempty(G.Nodes)
            disp('No points to save');
            return;
        end

        [pFileName, pPathName] = uiputfile('*.pMx', 'Save Point Coordinates As');
        
        if isequal(pFileName,0) || isequal(pPathName,0)
            disp('Saving canceled.');
            return;
        end
        
        [fFileName, fPathName] = uiputfile('*.fMx', 'Save faces As');
        
        if isequal(fFileName,0) || isequal(fPathName,0)
            disp('Saving canceled.');
            return;
        end


        
        ptCoords = table(G.Nodes.X, G.Nodes.Y, G.Nodes.Z, 'VariableNames', {'X', 'Y', 'Z'});
        writetable(ptCoords, fullfile(pPathName, pFileName),...
            'FileType','text', 'Delimiter', ' ', 'WriteVariableNames', false);

        faceTable = table(ones(height(G.Edges), 1), G.Edges.EndNodes(:, 1), G.Edges.EndNodes(:, 2), ...
            'VariableNames', {'GroupID', 'Source', 'Target'});
        writetable(faceTable, fullfile(fPathName, fFileName),...
            'FileType','text', 'Delimiter', ' ', 'WriteVariableNames', false);
        
        showTextOnFig(['Point coordinate matrix saved as: ', fullfile(pPathName, pFileName)]);
        showTextOnFig(['Face matrix saved as: ', fullfile(fPathName, fFileName)]);
    end

    % Update button state
    function updateBtnState(buttonIdx)
        if btnStates(buttonIdx) == 0
            % Set the selected button to blue and others to inactive (greyed out)
            set(btnHandles(buttonIdx), 'BackgroundColor', [0, 0, 1], 'ForegroundColor', [1, 1, 1]);
            set(btnHandles(setdiff(1:numel(btnHandles), buttonIdx)), 'Enable', 'off');
            btnStates(buttonIdx) = 1;
        else
            % Reset all buttons to white and active
            set(btnHandles, 'BackgroundColor', [1, 1, 1], 'Enable', 'on', 'ForegroundColor', [0, 0, 0]);
            btnStates(:) = 0;
        end
    end
    
    function showTextOnFig(text)
        set(showText, 'String', text);
    end

    % Function to toggle Object visibility
    function hideObjCb(~, ~)

        if isempty(rendererTable)
            showTextOnFig('No objects to hide, load objects and try again...')
            return
        end

        showObj = ~showObj; 
        bmpRows = strcmp(rendererTable.type, '.bmp');       
        objRows = find(strcmp(rendererTable.type, '.fMx') | strcmp(rendererTable.type, '.stl'));

        if showObj
            if ~isempty(bmpRows)
               set([rendererTable.drawHandle(bmpRows), rendererTable.viewHandle(bmpRows)], 'FaceAlpha', 1.0); 
            end    
            if ~isempty(objRows)
               set([rendererTable.drawHandle(objRows), rendererTable.viewHandle(objRows)], 'Visible', 'on');
            end
            set(hideObjBtn, 'String', 'Hide Obj');
        else
            if ~isempty(bmpRows)
               set([rendererTable.drawHandle(bmpRows), rendererTable.viewHandle(bmpRows)], 'FaceAlpha', 0.0); 
            end   
            if ~isempty(objRows)
               set([rendererTable.drawHandle(objRows), rendererTable.viewHandle(objRows)], 'Visible', 'off');
            end
            set(hideObjBtn, 'String', 'Show Obj');
        end

    end 

    function selectPlane(~, ~)
        set(fig, 'WindowButtonMotionFcn', @movePlane);
        set(fig, 'WindowButtonUpFcn', @unselectPlane);
    end
    
    function unselectPlane(~, ~)
        set(fig, 'WindowButtonMotionFcn', '');
        set(fig, 'WindowButtonUpFcn', '');
        switch toggleStates{currentState}
            case 'XY'
                z = get(axDraw, 'ZLim');
                currentThirdCoord = z(2);
            case 'YZ'
                x = get(axDraw, 'XLim');
                currentThirdCoord = x(2);
            case 'XZ'
                y = get(axDraw, 'YLim');
                currentThirdCoord = y(2);
        end
        coordEditBox.String = num2str(currentThirdCoord, "%.2f");
    end

    function movePlane(~, ~)
       currPosition = get(axView, 'CurrentPoint');
       switch toggleStates{currentState}
           case 'XY'
               z = currPosition(2, 3) * ones(100);
               set(drawPlane, 'ZData', z);
               thirdAxes = [currPosition(2, 3) - thickness, currPosition(2, 3)];
               zlim(axDraw, thirdAxes);
           case 'YZ'
               x = currPosition(1, 1) * ones(100);
               set(drawPlane, 'XData', x);
               thirdAxes = [currPosition(1, 1) - thickness, currPosition(1, 1)];
               xlim(axDraw, thirdAxes);
           case 'XZ'
               y = currPosition(1, 2) * ones(100);
               set(drawPlane, 'YData', y);
               thirdAxes = [currPosition(1, 2) - thickness, currPosition(1, 2)];
               ylim(axDraw, thirdAxes);
       end
    end
    
    function updateDrawPlane(ax, thirdCoord)
           
        switch toggleStates{currentState}
            case 'XY'
                xLimits = xlim(ax);
                yLimits = ylim(ax);
                [x, y] = meshgrid(linspace(xLimits(1), xLimits(2), 100), ...
                                  linspace(yLimits(1), yLimits(2), 100));
                z = thirdCoord * ones(100);
            case 'YZ'
                yLimits = ylim(ax);
                zLimits = zlim(ax);
                [y, z] = meshgrid(linspace(yLimits(1), yLimits(2), 100), ...
                                  linspace(zLimits(1), zLimits(2), 100));
                x = thirdCoord * ones(100);
            case 'XZ'
                xLimits = xlim(ax);
                zLimits = zlim(ax);
                [x, z] = meshgrid(linspace(xLimits(1), xLimits(2), 100), ...
                                  linspace(zLimits(1), zLimits(2), 100));
                y = thirdCoord * ones(100);
        end

        set(drawPlane, 'XData', x, 'YData', y, 'ZData', z);
    end

%%%%%%%%%%%%%%%%%%%%%% Utility functions %%%%%%%%%%%%%%%%%%%%%%%%%%%

    function expandAxesLimits(points)
        maxCoords = max(points, [], 1);
        minCoords = min(points, [], 1);
        padding = max(1, 0.1 * (maxCoords - minCoords)); %10% padding
        maxCoords = maxCoords + padding;
        minCoords = minCoords - padding;
        lims = [get(axView, 'XLim'); get(axView, 'YLim'); get(axView, 'ZLim')];
        newLims = [min([minCoords; lims(:, 1).']) ; max([maxCoords; lims(:, 2).'])];
        set(axView, {'XLim', 'YLim', 'ZLim'}, {newLims(:, 1), newLims(:, 2), newLims(:, 3)});
        switch toggleStates{currentState}
            case 'XY'
                set(axDraw, {'XLim', 'YLim'}, {newLims(:, 1), newLims(:, 2)});
            case 'YZ'
                set(axDraw, {'YLim', 'ZLim'}, {newLims(:, 2), newLims(:, 3)});
            case 'XZ'
                set(axDraw, {'XLim', 'ZLim'}, {newLims(:, 1), newLims(:, 3)});
        end
        updateDrawPlane(axView, currentThirdCoord);
        daspect(axDraw, [1 1 1]);
        daspect(axView, [1 1 1]);
    end

    function rePlotGraph()

        delete(plotObjDraw);
        delete(plotObjView);
  
        % Replot the graph with updated coordinates
        hold(axDraw, 'on');
        plotObjDraw = plot(axDraw, G, 'XData', G.Nodes.X, 'YData', G.Nodes.Y,...
            'ZData', G.Nodes.Z, 'Marker', 'o', 'NodeColor', [0 0.5 0], 'EdgeColor', [0.5 0.25 0]);
        hold(axDraw, 'off');

        hold(axView, 'on');
        plotObjView = plot(axView, G, 'XData', G.Nodes.X, 'YData', G.Nodes.Y,...
            'ZData', G.Nodes.Z, 'Marker', 'o', 'NodeColor', [0 0.5 0], 'EdgeColor', [0.5 0.25 0]);
        hold(axView, 'off');

        if deleteMode
            set(plotObjDraw, 'ButtonDownFcn', @deleteFromGraph);
        elseif connectMode
            set(plotObjDraw, 'ButtonDownFcn', @connectPoints);
        elseif editMode
            set(plotObjDraw, 'ButtonDownFcn', @editPoint);
        else
            set(plotObjDraw, 'ButtonDownFcn', @startDragging);
        end
       
    end

    % Function to find the nearest point in graph to a clicked point
    function pointIdx = findNearestPoint(clickPoint)

        % Calculate the range of each axis
        xRange = diff(xlim(axDraw));
        yRange = diff(ylim(axDraw));
        zRange = diff(zlim(axDraw));
    
        % Calculate dynamic tolerances based on the axis ranges
        dynamicToleranceX = xRange * 1e-2;
        dynamicToleranceY = yRange * 1e-2;
        dynamicToleranceZ = zRange * 1e-2;

        switch toggleStates{currentState}
            case 'XY' 
                pointIdx = find(abs(G.Nodes.X - clickPoint(1)) < dynamicToleranceX & abs(G.Nodes.Y - clickPoint(2)) < dynamicToleranceY);
            case 'YZ'
                pointIdx = find(abs(G.Nodes.Y - clickPoint(2)) < dynamicToleranceY & abs(G.Nodes.Z - clickPoint(3)) < dynamicToleranceZ);
            case 'XZ'
                pointIdx = find(abs(G.Nodes.X - clickPoint(1)) < dynamicToleranceX & abs(G.Nodes.Z - clickPoint(3)) < dynamicToleranceZ);
        end
    end

    function autoConnectExistingPts(~, ~)
        for i = 1:np-1
            G = addedge(G, i, i+1);
        end

        if np > 1
            rePlotGraph();
        end
    end

end