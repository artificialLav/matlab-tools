function [ nodes ] = plotViewer()

   fig = uifigure('Name', 'Properties Window', 'Position', [1000 400 350 800]);

   axesFig = figure('Name', 'Axes Window', ...
       'Position', [50 400 900 800]);
   ax = axes(axesFig, 'Units','normalized',...
       "Position", [0.2 0.2 0.7 0.7]);

   global nwk;
   global G;
   global plotHandle;
   global bbHandle;
   global grpBoxHandles;
   
   nwk = struct();
   G = graph([], []);
   plotHandle = plot3([], [], []);
   faceProp = [];


   % Plot the graph in a uipanel in the same window as the ui buttons
   %uiplot = uipanel(fig, 'Position', [400 120 750 600]);
   %ax = uiaxes(uiplot, 'Units','normalized',...
   %     "Position", [0 0 1 1]);

   % rotate3d on;
   view(ax,-45,40);
   colorbar;
   xlabel(ax,'x (mm)');
   ylabel(ax,'y (mm)');
   zlabel(ax,'Cortical Depth (mm)');
   title(ax,'Microcirculatory Network Viewer');
   ax.XLim = [-1, 1];
   ax.YLim = [-1, 1];
   ax.ZLim = [-1, 1];

   %Create tabbed panels (if parent is figure for tabbed group, position should be in percentages)
   tabgp = uitabgroup(fig,"Position",[20 20 300 700]);
   tab1 = uitab(tabgp,"Title","View", "BackgroundColor",[0.8 0.8 0.8]);
   tab2 = uitab(tabgp,"Title","Edit", "BackgroundColor",[0.8 0.8 0.8]);
   tab3 = uitab(tabgp, "Title","Transform/Scale", "BackgroundColor",[0.8 0.8 0.8]);

   %Create load and clear buttons in Properties window
   loadButton = uibutton(fig, 'push', 'Text', 'Load', 'Position', [22, 740, 50, 30], ...
        'ButtonPushedFcn', {@loadButtonCb, ax});

   clearButton = uibutton(fig, 'push', 'Text', 'Clear', 'Position', [80, 740, 50, 30], ...
        'ButtonPushedFcn', @clearPlotCb);

    % Text above the buttons
    uicontrol(fig, 'Style', 'text', 'String', 'Zoom Axes', ...
        'Position', [245, 770, 100, 20], 'HorizontalAlignment', 'center');

    % Create zoom in button
    btnZoomIn = uicontrol(fig, 'Style', 'pushbutton', 'String', '+', ...
        'Position', [260, 740, 20, 20], 'Callback', {@axesZoomInCb, ax});

    % Create zoom out button
    btnZoomOut = uicontrol(fig, 'Style', 'pushbutton', 'String', '-', ...
        'Position', [290, 740, 20, 20], 'Callback', {@axesZoomOutCb, ax});


   %toggleButton = uicontrol(axesFig, 'Style', 'togglebutton', 'String', 'Toggle', ...
   %                       'Position', [20 20 100 30], 'Callback', {@togglePlotCb, ax});

   snapShotBtn = uicontrol(axesFig, 'Style', 'pushbutton', 'String', 'Snapshot', ...
                          'Position', [20 20 100 30], 'Callback', @snapshotCb);


   %Create first group of checkboes in View tab
   labelsOn = uicheckbox(tab1, "Text", "labelsOn",...
       "Position",[22 640 70 22], 'ValueChangedFcn', {@labelsOnCb});

   directionsOn = uicheckbox(tab1, "Text", "directionsOn",...
       "Position",[22 620 100 22], 'ValueChangedFcn', {@directionsOnCb, ax});

   ptSelect = uicheckbox(tab1, "Text", "PtSelect",...
       "Position",[22 600 70 22],...
       "ValueChangedFcn", @ptSelectCb);

   toggleCylindersView = uicheckbox(tab1, "Text", "toggleCylindersView",...
       "Position",[140 640 130 22],...
       "ValueChangedFcn", @togglePlotCb);

   boundingBoxOn = uicheckbox(tab1, "Text", "BoundingBoxOn",...
       "Position",[140 620 110 22], ...
       "ValueChangedFcn", @boundingBoxCb);
   
   faceSelect = uicheckbox(tab1, "Text", "faceSelect",...
       "Position",[140 600 80 22],...
       "ValueChangedFcn", @faceSelectCb);

   %Create transparency textbox in View tab
   transparencyLabel = uilabel(tab1, 'Text', 'Transparency',...
       'Position', [80, 575, 80, 22]);
   transparency = uieditfield(tab1,"numeric",...
       "Value", [],...
       "Limits",[-5 10],...
       "AllowEmpty","on",...
       "Position", [165 575 100 22]);

   %Create a button group for Endpoints and Endfaces in View tab
   endpointsGrp = uibuttongroup(tab1, "Title", "Show EndPoints",...
       "TitlePosition","lefttop",...
       "Position", [20, 490, 260, 80],...
       "BackgroundColor",[0.8 0.8 0.8], ...
       "SelectionChangedFcn", {@updateEndPoints, ax});

   endfacesGrp = uibuttongroup(tab1, "Title", "Show EndFaces",...
       "TitlePosition","lefttop",...
       "Position", [20, 405, 260, 80],...
       "BackgroundColor",[0.8 0.8 0.8], ...
       "SelectionChangedFcn", {@updateEndFaces, ax});

   %Create radio buttons in Endpoints and Endfaces in Buttongroup
   ptNoneRb1 = uiradiobutton(endpointsGrp, "Text", "None", "Position", [10 30 80 20], 'Value', true);
   ptAllRb2 = uiradiobutton(endpointsGrp, 'Text', 'All EndPoints', 'Position', [10 5 100 20]);
   ptInletRb3 = uiradiobutton(endpointsGrp, 'Text', 'InletPoints', 'Position', [130 30 80 20]);
   ptOutletRb4 = uiradiobutton(endpointsGrp, 'Text', 'OutletPoints', 'Position', [130 5 100 20]);

   facesRb1 = uiradiobutton(endfacesGrp, "Text", "None", "Position", [10 30 80 20]);
   facesRb2 = uiradiobutton(endfacesGrp, 'Text', 'All EndFaces', 'Position', [10 5 100 20]);
   facesRb3 = uiradiobutton(endfacesGrp, 'Text', 'InletFaces', 'Position', [130 30 80 20]);
   facesRb4 = uiradiobutton(endfacesGrp, 'Text', 'OutletFaces', 'Position', [130 5 100 20]);

   %Create panel for selection and edits in View tab
   editGrp = uipanel(tab1,...
       "Position", [20, 250, 260, 150],...
       "BackgroundColor",[0.8 0.8 0.8]);

   selectionGrp = uibuttongroup(tab1, "Title", "selectionGroup",...
       "TitlePosition","lefttop",...
       "Position", [24, 325, 240, 70],...
       "BackgroundColor",[0.8 0.8 0.8], ...
       "SelectionChangedFcn", @updateSelections);

   %Create radio buttons in selection Group Buttongroup
   selectionRb1 = uiradiobutton(selectionGrp, "Text", "None",...
       'Value', true, "Position", [10 28 80 20]);
   selectionRb2 = uiradiobutton(selectionGrp, 'Text', 'Pt and Face Selections',...
       'Position', [10 5 180 20]);
   
   %Create face edit label and edit box
   faceEditLabel = uilabel(tab1, 'Text', 'faceEdit',...
       'Position', [25 305 50 15]);
   
   faceEditBox = uieditfield(tab1, "InputType", "text", ...
       "CharacterLimits", [0 Inf], ...
       "Position", [80 305 110 15]);

   %Create point edit label and edit box
   ptEditLabel = uilabel(tab1, 'Text', 'pointEdit',...
       'Position', [25 285 50 15]);
   
   ptEditBox = uieditfield(tab1, "InputType", "text", ...
       "CharacterLimits", [0 Inf], ...
       "Position", [80 285 110 15]);

   %Create the Display and Reset button
   displayButton = uibutton(tab1, 'Text', 'Display',...
       'Position', [70 260 70 20],...
       'ButtonPushedFcn', @updateSelections);

   resetButton = uibutton(tab1, 'Text', 'Reset',...
       'Position', [160 260 70 20],...
       'ButtonPushedFcn', @resetSelections);

   %Create a bifurcation panel
   bifurcationGrp = uipanel(tab1,...
       "Title", "bifurcationInspection",...
       "TitlePosition","lefttop",...
       "Position", [20, 165, 260, 80],...
       "BackgroundColor",[0.8 0.8 0.8]);

   pointEditLabel = uilabel(tab1, 'Text', 'bifurcationSelection',...
       'Position', [25 195 120 20]);

   %Create the Display and Reset button
   displayButton = uibutton(tab1, 'Text', 'Display',...
       'Position', [70 170 70 20],...
       'ButtonPushedFcn', @displayButtonCallback);

   resetButton = uibutton(tab1, 'Text', 'ResetBif',...
       'Position', [160 170 70 20],...
       'ButtonPushedFcn', @resetButtonCallback);


   %Create facegroup
   faceGrp = uipanel(tab1,...
       "Title", "FaceGroup",...
       "TitlePosition","lefttop",...
       "Position", [20, 10, 260, 150],...
       "BackgroundColor",[0.8 0.8 0.8]);

   faceGrpEditBox = uieditfield(faceGrp, "InputType", "text", ...
       "CharacterLimits", [0 Inf], ...
       "Position", [15 10 220 110], ...
       'Editable', 'off', ...
       'ValueChangedFcn', @faceGrpEditCb);


   %Initialise the starting Limits for X, Y, Z axes
   global initialXLimits;
   global initialYLimits;
   global initialZLimits;

   initialXLimits = [0 5];
   initialYLimits = [0 5];
   initialZLimits = [0 5];

    %Create a UI slider for X axis
    xSliderLabel = uilabel(tab3, 'Text', 'XLim',...
       'Position', [20 640 50 20], 'FontSize', 15);

    xSlider = uislider(tab3, "range", ...
        'Position', [75 640 150, 3], ...
        'Value', initialXLimits, ...
        'Limits', [-10, 10], ...
        'ValueChangedFcn', {@updateXLimit, ax});

    function updateXLimit(~, event, ax)
    
        currentLimits = event.Value;
    
        if currentLimits(1) ~= initialXLimits(1)
            xlim(ax, [currentLimits(1), initialXLimits(2)]);
        elseif currentLimits(2) ~= initialXLimits(2)
            xlim(ax, [initialXLimits(1), currentLimits(2)]);
        end

        initialXLimits = currentLimits;
    
    end

    %Create a UI slider for Y axis
    ySliderLabel = uilabel(tab3, 'Text', 'YLim', ...
         'Position', [20 580 50 20], 'FontSize', 15);

    ySlider = uislider(tab3, "range", ...
        'Position', [75 580 150 3], ...
        'Value', initialYLimits, ...
        'Limits', [-10, 10], ...
        'ValueChangedFcn', {@updateYLimit, ax});

    function updateYLimit(~, event, ax)
    
        currentLimits = event.Value;
    
        if currentLimits(1) ~= initialYLimits(1)
            ylim(ax, [currentLimits(1), initialYLimits(2)]);
        elseif currentLimits(2) ~= initialYLimits(2)
            ylim(ax, [initialYLimits(1), currentLimits(2)]);
        end

        initialYLimits = currentLimits;
    
    end

    %Create a UI slider for Z axis
    zSliderLabel = uilabel(tab3, 'Text', 'ZLim', ...
         'Position', [20 520 50 20], 'FontSize', 15);

    zSlider = uislider(tab3, "range", ...
        'Position', [75 520 150 3], ...
        'Value', initialZLimits, ...
        'Limits', [-10, 10], ...
        'ValueChangedFcn', {@updateZLimit, ax});

    function updateZLimit(~, event, ax)
    
        currentLimits = event.Value;
    
        if currentLimits(1) ~= initialZLimits(1)
            zlim(ax, [currentLimits(1), initialZLimits(2)]);
        elseif currentLimits(2) ~= initialZLimits(2)
            zlim(ax, [initialZLimits(1), currentLimits(2)]);
        end

        initialZLimits = currentLimits;
    
    end

    displayState = 'graph';
    
    function togglePlotCb(~, ~)

        children = get(ax, 'Children');
        delete(children);

        if strcmp(displayState, 'graph')
            G = graph(nwk.faceMx(:, 2), nwk.faceMx(:, 3));  

            faceMxTemp = nwk.faceMx( :, 2 : 3 );
            [ faceMxTemp, ~ ] = sort( faceMxTemp,  2 );
            [     ~     , sortColumn   ] = sort( faceMxTemp(:, 2));
            faceMxTemp = faceMxTemp( sortColumn, : );
            [     ~     , sortRow      ] = sort( faceMxTemp(:,1));

            G.Edges.dia       =     nwk.dia( sortColumn( sortRow ));
            faceProp = nwk.dia;
            G.Edges.EdgeCData =     faceProp( sortColumn( sortRow ));

            edgesMx = table2array(G.Edges);
            colorSub = edgesMx( :, 4 );

            hold(ax, 'on');
            RenderTubesAsTrianglesTV(nwk.ptCoordMx, nwk.faceMx, nwk.dia, colorSub, [], [], 'arc faceMx', jet(256));
            hold(ax, 'off');

            displayState = 'tubes';
        else
            plotGraph();
        end

    end


    function loadButtonCb(~, ~, ax)

         [file, path] = uigetfile('*.bmp;*.fMx;*.stl', 'Select a file to load');
         if isequal(file, 0) || isequal(path, 0)
              disp('File selection canceled');
              return
         end

         [~, name, ext] = fileparts(fullfile(path, file));

         nwk = nwkHelp.load(fullfile(path, name));
         plotGraph();
         initGroupBox()


         % if strcmp(ext, '.bmp')
         %      % [drawHandle, viewHandle = loadBmp(path, file);
         %      % file = [file, '(z=', num2str(currentThirdCoord), ')'];
         % 
         % elseif strcmp(ext, '.fMx')
         % 
         %       nwk = nwkHelp.load(fullfile(filePath, name));
         %       plotHandle = plotGraph();
         %       displayState = 'graph';
         % 
         % elseif strcmp(ext, '.stl')
         % 
         %       plotHandle = loadStl(path, file, ax);
         % 
         % 
         % end
         
        %rendererTable = [rendererTable; {file, ext, drawHandle, viewHandle}];
 


        % Check if a PNG file exists for the loaded file
        pngName = fullfile(path, [name, '.png']);
        if ~exist(pngName, 'file')
            % Create a small PNG file
            nwkHelp.saveAsPng(ax, pngName);
            disp(['Created a PNG file for the loaded file: ', pngName]);
        end
       
    end

    function initGroupBox()
        uniqueGroupIDs = unique(nwk.faceMx(:, 1));
        grpBoxHandles = cell(numel(uniqueGroupIDs), 1);
        
        for i = 1:numel(uniqueGroupIDs)
            grpBoxHandles{i} = uicheckbox(faceGrp, 'Text', num2str(uniqueGroupIDs(i)),...
                'Value', true, 'Position', [20, 10 + i * 20 + 5 , 30, 20], 'ValueChangedFcn', @faceGrpEditCb);
        end
    end

    function clearPlotCb(~, ~)
        children = get(ax, 'Children');
        delete(children);

        % Delete the group checkboxes for a particular plot
        for i = 1:numel(grpBoxHandles)
            delete(grpBoxHandles{i});
        end
    end



    % function [ stlHandle ] = loadStl(path, file, ax)
    % 
    %     [TR, ~, ~, ~] = stlread(fullfile(path, file));
    %     nwk.ptCoordMx = TR.Points;
    %     nwk.faceMx = TR.ConnectivityList;
    %     nwk.dia = [];
    % 
    %     hold(ax, 'on');
    %     stlHandle = patch(ax, 'Faces', nwk.faceMx, 'Vertices', nwk.ptCoordMx,...
    %         'FaceColor', '[0.5 0.5 0.5]', 'EdgeColor', '[0.45 0.45 0.45]');
    %     hold(ax, 'off');
    % 
    %     expandAxesLimits(ax);
    % 
    % end


    function plotGraph()
        edgeNumbers = 1:nwk.nf;
        G = graph(nwk.faceMx(:, 2), nwk.faceMx(:, 3), edgeNumbers);

        hold(ax, 'on');
        delete(plotHandle);
        plotHandle = plot(G, 'XData', nwk.ptCoordMx(:, 1), 'YData', nwk.ptCoordMx(:, 2),...
            'ZData', nwk.ptCoordMx(:, 3), 'NodeColor', '[0 0 0.5]',...
            'EdgeColor', '[0 0 0.5]', 'NodeLabel', {}, 'MarkerSize', 2, 'LineWidth', 2, 'Parent', ax);
        hold(ax, 'off');

        displayState ='graph';
            
        expandAxesLimits(ax);
    end

    function expandAxesLimits(ax)
        maxLims = max(nwk.ptCoordMx);
        minLims = min(nwk.ptCoordMx);
        padding = 0.1*(maxLims - minLims);

        upperLims = maxLims + padding;
        lowerLims = minLims - padding;

        if ~isempty(nwk.dia)
            maxDia = max(nwk.dia);
            upperLims = upperLims + maxDia * 8;
            lowerLims = lowerLims - maxDia * 8;
        end

        xlims = get(ax, 'XLim');
        ylims = get(ax, 'YLim');
        zlims = get(ax, 'ZLim');
        
        xlDefault = [min(lowerLims(1), xlims(1)), max(upperLims(1), xlims(2))];
        ylDefault = [min(lowerLims(2), ylims(1)), max(upperLims(2), ylims(2))];
        zlDefault = [min(lowerLims(3), zlims(1)), max(upperLims(3), zlims(2))];
        ax.XLim = xlDefault;
        ax.YLim = ylDefault;
        ax.ZLim = zlDefault;
    end
    
    function snapshotCb(~, ~)
        [filename, pathname] = uiputfile({'*.png', 'PNG Files (*.png)'}, 'Save As');
        if isequal(filename, 0) || isequal(pathname, 0)
            disp('Error: User canceled the operation.');
            return;
        end
        filepath = fullfile(pathname, filename);
        %saveas(axesFig, filepath, 'png'); %the figure view
        exportgraphics(ax, filepath, 'ContentType', 'image', 'Resolution', 300);
    end

    function writeToReport(text, ptList, faceList)
        fid = fopen('draw_report.txt', 'a');        
        if fid == -1
            error('Unable to open or create report.txt');
        end

        fprintf(fid, '\n%s', text);
        if ~isempty(ptList)
            fprintf(fid, '\n');
            for i=1:length(ptList)
                fprintf(fid, '%s: %s\n', num2str(ptList(i)), num2str(nwk.ptCoordMx(ptList(i), :)));
            end
        end

        if ~isempty(faceList)
            fprintf(fid, '\n');
            for i=1:length(faceList)
                fprintf(fid, '%s: %s\n', num2str(faceList(i)), num2str(nwk.faceMx(faceList(i), :)));
            end
        end
        
        fclose(fid);
    end

    function boundingBoxCb(~, ~)

        if  boundingBoxOn.Value
        
            % Define padding percentage
            padding = 0.1;
            
            % Determine bounding box limits
            minX = min(nwk.ptCoordMx(:, 1));
            maxX = max(nwk.ptCoordMx(:, 1));
            minY = min(nwk.ptCoordMx(:, 2));
            maxY = max(nwk.ptCoordMx(:, 2));
            minZ = min(nwk.ptCoordMx(:, 3));
            maxZ = max(nwk.ptCoordMx(:, 3));
            
            % Calculate range for each dimension
            rangeX = maxX - minX;
            rangeY = maxY - minY;
            rangeZ = maxZ - minZ;
            
            % Apply padding to the range
            minX = minX - padding * rangeX;
            maxX = maxX + padding * rangeX;
            minY = minY - padding * rangeY;
            maxY = maxY + padding * rangeY;
            minZ = minZ - padding * rangeZ;
            maxZ = max(maxZ + padding * rangeZ, 1);
    
            % Define vertices of the bounding box
            vertices = [
                minX, minY, minZ;
                maxX, minY, minZ;
                maxX, maxY, minZ;
                minX, maxY, minZ;
                minX, minY, maxZ;
                maxX, minY, maxZ;
                maxX, maxY, maxZ;
                minX, maxY, maxZ
            ];
    
            % Define the edges of the bounding box
            edges = [ 1, 2; 2, 3; 3, 4; 4, 1; 5, 6; 6, 7; 7, 8;
                      8, 5; 1, 5; 2, 6; 3, 7; 4, 8];

            bbGraph = graph(edges(:,1), edges(:,2));
    
            hold(ax, "on");
            bbHandle = plot(bbGraph, 'XData', vertices(:,1), 'YData', vertices(:,2),...
                'ZData', vertices(:,3), 'EdgeColor', 'k',...
                'NodeColor', 'k', 'LineWidth', 2, ...
                'NodeLabel', {});
            hold(ax, "off");
        else
            delete(bbHandle);
        end

    end

    function labelsOnCb(~, ~)

        if labelsOn.Value
            ptLabels = strcat('p', cellstr(num2str((1:nwk.np)')));
            faceLabels = strcat('f', arrayfun(@num2str, G.Edges.Weight, 'UniformOutput', false));
            set(plotHandle, 'NodeLabel', ptLabels, 'EdgeLabel', faceLabels);
        else
            set(plotHandle, 'NodeLabel', '', 'EdgeLabel', '');
        end

    end

    function directionsOnCb(~, ~, ax)

        if directionsOn.Value
            edgeNumbers = 1:nwk.nf;
            G = digraph(nwk.faceMx(:,2), nwk.faceMx(:,3), edgeNumbers);
             hold(ax, 'on');
             delete(plotHandle);
             plotHandle = plot(G, 'XData', nwk.ptCoordMx(:,1), 'YData', nwk.ptCoordMx(:,2),...
             'ZData', nwk.ptCoordMx(:,3), 'NodeColor', '[0 0 0.5]',...
             'EdgeColor', '[0 0 0.5]', 'NodeLabel', {},...
             'MarkerSize', 2, 'LineWidth', 2, 'Parent', ax);
             hold(ax, 'off');
        else
             plotGraph();
        end

        % The directions On or Off, should keep the labels on if LabelsOn is
        % checked.
        if labelsOn.Value
            labelsOnCb();
        end

    end

    function updateEndPoints(~, event, ax)

        [inlet, outlet] = nwkHelp.findBoundaryNodes(nwk);

        if strcmp(event.NewValue.Text, 'None')
            plotGraph();
            return;
        elseif strcmp(event.NewValue.Text, 'InletPoints')
            ptsIdx = inlet;
        elseif strcmp(event.NewValue.Text, 'OutletPoints')
            ptsIdx = outlet;
        elseif strcmp(event.NewValue.Text, 'All EndPoints')
            ptsIdx = [inlet outlet];
        end

        set(plotHandle, 'NodeColor', 'k', 'MarkerSize', 2);
        highlight(plotHandle, ptsIdx, 'NodeColor', 'red', 'MarkerSize', 8);

    end

    function updateEndFaces(~, event, ax)

        [inlet, outlet] = nwkHelp.findBoundaryFaces(nwk);

        if strcmp(event.NewValue.Text, 'None')
            plotGraph();
            return;
        elseif strcmp(event.NewValue.Text, 'InletFaces')
            faceIdx = inlet;
        elseif strcmp(event.NewValue.Text, 'OutletFaces')
            faceIdx = outlet;
        elseif strcmp(event.NewValue.Text, 'All EndFaces')
            faceIdx = [inlet outlet];
        end

        faceRows = find(ismember(G.Edges.Weight(:), faceIdx));

        set(plotHandle, 'EdgeColor', 'k', 'LineWidth', 2);
        highlight(plotHandle, G.Edges.EndNodes(faceRows, 1),...
            G.Edges.EndNodes(faceRows, 2), 'EdgeColor', 'red', 'LineWidth', 4);

    end

    set(axesFig, 'WindowButtonDownFcn', @mouseClickCb);
    global initialMousePos;
    
    function mouseClickCb(src, ~)

        if strcmp(src.SelectionType, 'alt') % Right mouse click
            set(axesFig, 'WindowButtonMotionFcn', @rotateCb);
        elseif strcmp(src.SelectionType, 'normal') % Left mouse click
            set(axesFig, 'WindowButtonMotionFcn', @moveHorizVertCb);
        end
        
        set(axesFig, 'WindowButtonUpFcn', @stopMovingCb);

    end

    function rotateCb(src, ~)
       if isempty(initialMousePos)
           initialMousePos = get(src, 'CurrentPoint');
           return;
       end
        
       currentMousePos = get(src, 'CurrentPoint');
       dx = currentMousePos(1) - initialMousePos(1);
       dy = currentMousePos(2) - initialMousePos(2);
       camorbit(ax, -dx, -dy, 'camera');
        
       % Update initial mouse position for next callback
       initialMousePos = currentMousePos;
    end
    
    function moveHorizVertCb(src, ~)
        if isempty(initialMousePos)
            initialMousePos = get(src, 'CurrentPoint');
            return;
        end
            
        currentMousePos = get(src, 'CurrentPoint');
        dx = currentMousePos(1) - initialMousePos(1);
        dy = currentMousePos(2) - initialMousePos(2);
        camdolly(ax, -dx, -dy, 0, 'movetarget', 'pixels');
            
         % Update initial mouse position for next callback
        initialMousePos = currentMousePos;
    end
    
    function stopMovingCb(~, ~)
        set(axesFig, 'WindowButtonMotionFcn', '');
        set(axesFig, 'WindowButtonUpFcn', '');
        initialMousePos = [];
    end

    set(axesFig, 'WindowScrollWheelFcn', @zoomCb);

    function zoomCb(~, event)
        % Scroll distance is +ve for scrolling up, -ve for scrolling down
        scrollDist = event.VerticalScrollCount;

        % Fraction of total distance to move the camera
        fraction = 0.1;
        
        camPos = get(ax, 'CameraPosition');
        camTarget = get(ax, 'CameraTarget');
        newCamPos = camPos - scrollDist * fraction * (camPos - camTarget);
        set(ax, 'CameraViewAngleMode', 'manual', 'CameraPosition', newCamPos);
    end

    function axesZoomInCb(~, ~, ax)
        % Get current axes limits
        xlims = get(ax, 'XLim');
        ylims = get(ax, 'YLim');
        zlims = get(ax, 'ZLim');
        step = 0.1;
        
        % Calculate new axis limits for zoom in
        new_xlims = [xlims(1) + diff(xlims) * step, xlims(2) - diff(xlims) * step];
        new_ylims = [ylims(1) + diff(ylims) * step, ylims(2) - diff(ylims) * step];
        new_zlims = [zlims(1) + diff(zlims) * step, zlims(2) - diff(zlims) * step];
        
        
        if new_xlims(1) < new_xlims(2) && new_ylims(1) < new_ylims(2) && new_zlims(1) < new_zlims(2)
            % Set new axes limits
            set(ax, 'XLim', new_xlims, 'YLim', new_ylims, 'ZLim', new_zlims);
        end
    
    end
    function axesZoomOutCb(~, ~, ax)
        % Get current axes limits
        xlims = get(ax, 'XLim');
        ylims = get(ax, 'YLim');
        zlims = get(ax, 'ZLim');
        step = 0.1;
        
        % Calculate new axis limits for zoom out
        new_xlims = [xlims(1) - diff(xlims) * step, xlims(2) + diff(xlims) * step];
        new_ylims = [ylims(1) - diff(ylims) * step, ylims(2) + diff(ylims) * step];
        new_zlims = [zlims(1) - diff(zlims) * step, zlims(2) + diff(zlims) * step];
 
        % Set new axes limits
        set(ax, 'XLim', new_xlims, 'YLim', new_ylims, 'ZLim', new_zlims);
    end

    % Callback function for the checkbox
    function faceSelectCb(src, ~)
        dcm_obj = datacursormode(axesFig);
        if src.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @highlightEdgesFromNearestNode);
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            plotGraph();
        end
    end

    function txt = highlightEdgesFromNearestNode(~, event)
         nodeCoords = event.Position;
         [~, nodeIndex] = ismember(nodeCoords, nwk.ptCoordMx,'rows');
         faceIdx = find(G.Edges.EndNodes(:, 1) == nodeIndex | G.Edges.EndNodes(:, 2) == nodeIndex);
        % faceIdx = G.Edges.Weight(idx);

         set(plotHandle, 'EdgeColor', 'k', 'LineWidth', 2);
         highlight(plotHandle, G.Edges.EndNodes(faceIdx, 1), G.Edges.EndNodes(faceIdx, 2), ...
             'EdgeColor', 'red', 'LineWidth', 4);

         writeToReport('Selected faces: ', [], faceIdx);
  
         txt = ['Node ', num2str(nodeIndex)];
    end
   
    % Callback function for the checkbox
    function ptSelectCb(src, ~)
        dcm_obj = datacursormode(axesFig);
        if src.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @selectPt);
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            plotGraph();
        end
    end


    function txt = selectPt(~, event)
         nodeCoords = event.Position;
         [~, nodeIndex] = ismember(nodeCoords, nwk.ptCoordMx, 'rows');

         set(plotHandle, 'NodeColor', 'k', 'MarkerSize', 2);
         highlight(plotHandle, nodeIndex, 'NodeColor', 'red', 'MarkerSize', 8);
         
         writeToReport('Selected points: ', nodeIndex, []);

         txt = ['Node ', num2str(nodeIndex)];
    end

    function updateSelections(~, ~)
        ptsList = ptEditCb();
        facesList = faceEditCb();

        if selectionRb2.Value
            plotSubsetFacesPts(facesList, ptsList);
        else

            plotGraph();

            set(plotHandle, 'NodeColor', 'k', 'MarkerSize', 2);
            highlight(plotHandle, ptsList, 'NodeColor', 'red', 'MarkerSize', 8);

            set(plotHandle, 'EdgeColor', 'k', 'LineWidth', 2);
            highlight(plotHandle, G.Edges.EndNodes(facesList, 1),...
                G.Edges.EndNodes(facesList, 2), 'EdgeColor', 'red', 'LineWidth', 4);
        end

         writeToReport('Selected points and faces: ', ptsList, facesList);

    end

    function resetSelections(~, ~)
        selectionRb2.Value = false;
        selectionRb1.Value = true;
        faceEditBox.Value = '';
        ptEditBox.Value = '';
        plotGraph();
    end

    function [ptsList] = ptEditCb()
        input_str = ptEditBox.Value;
        input_str = strrep(input_str, ' ', '');  % Remove whitespace
        input_values = strsplit(input_str, ',');  % Split by comma
        
        ptsList = [];
        for i = 1:numel(input_values)
            value = input_values{i};
            
            if contains(value, ':')
                range_values = str2num(value);
                ptsList = [ptsList, range_values];
            elseif contains(value, 'p')
                if contains(value, '>')
                    index = str2double(value(3:end));
                    ptsList = [ptsList, (index+1):nwk.np];
                elseif contains(value, '<')
                    index = str2double(value(3:end));
                    ptsList = [ptsList, 1:(index-1)];
                elseif contains(value, '%')
                    divisor = str2double(value(3:end));
                    ptsList = [ptsList, divisor:divisor:nwk.np];
                end
            else
                index = str2double(value);
                if ~isnan(index) && index >= 1 && index <= nwk.np
                    ptsList = [ptsList, index];
                else
                    disp(['Invalid input: ', value]);
                end
            end
        end

    end

    function [faceList] = faceEditCb()
        input_str = faceEditBox.Value;
        input_str = strrep(input_str, ' ', '');  % Remove whitespace
        input_values = strsplit(input_str, ',');  % Split by comma
        
        faceList = [];
        for i = 1:numel(input_values)
            value = input_values{i};
            
            if contains(value, ':')
                range_values = str2num(value);
                faceList = [faceList, range_values];
            elseif contains(value, 'f')
                if contains(value, '>')
                    index = str2double(value(3:end));
                    faceList = [faceList, (index+1):nwk.nf];
                elseif contains(value, '<')
                    index = str2double(value(3:end));
                    faceList = [faceList, 1:(index-1)];
                elseif contains(value, '%')
                    divisor = str2double(value(3:end));
                    faceList = [faceList, divisor:divisor:nwk.nf];
                end
            else
                index = str2double(value);
                if ~isnan(index) && index >= 1 && index <= nwk.nf
                    faceList = [faceList, index];
                else
                    disp(['Invalid input: ', value]);
                end
            end
        end

    end

    function faceGrpEditCb(~, ~)

        checkedGroupIDs = [];
        for i = 1:numel(grpBoxHandles)
            if grpBoxHandles{i}.Value
                groupID = str2double(grpBoxHandles{i}.Text);
                checkedGroupIDs = [checkedGroupIDs, groupID];
            end
        end

        facesList = find(ismember(nwk.faceMx(:, 1), checkedGroupIDs));
        plotSubsetFacesPts(facesList, []);

    end

    function plotSubsetFacesPts(facesList, ptsList)

            uniquePts = [];
            subG = graph([], []);
            if ~isempty(facesList)
                uniquePts = unique(nwk.faceMx(facesList, 2:3));
                newFaces = zeros(size(facesList, 1), 2);
                indexMap = containers.Map(uniquePts, 1:length(uniquePts));
                for i = 1:numel(facesList)
                      newFaces(i, :) = [indexMap(nwk.faceMx(facesList(i), 2)), indexMap(nwk.faceMx(facesList(i), 3))];
                end
                subG = graph(newFaces(:, 1), newFaces(:, 2));

                subG.Nodes.XData = nwk.ptCoordMx(uniquePts, 1);
                subG.Nodes.YData = nwk.ptCoordMx(uniquePts, 2);
                subG.Nodes.ZData = nwk.ptCoordMx(uniquePts, 3);
            end

            if ~isempty(ptsList)
                diffPtsList = setdiff(ptsList, uniquePts);
                subG = addnode(subG, size(diffPtsList, 2));
                if isempty(uniquePts)
                    np = 0;
                else
                    np = size(uniquePts, 1);
                end

                for i = 1:length(diffPtsList)
                    idx = np + i;
                    subG.Nodes{idx, {'XData', 'YData', 'ZData'}} = nwk.ptCoordMx(diffPtsList(i), :);
                end
            end

            hold(ax, "on");
            delete(plotHandle);
            plotHandle = plot(ax, subG, 'XData', subG.Nodes.XData, ...
                'YData', subG.Nodes.YData, ...
                'ZData', subG.Nodes.ZData, ...
                'NodeColor', 'k',...
                'EdgeColor', 'k', 'NodeLabel', {}, ...
                'MarkerSize', 2, 'LineWidth', 2) ;
            hold(ax, "off");
    end    

end
