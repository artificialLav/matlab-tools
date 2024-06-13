function [ nodes ] = nwkViewer()

   clear all;

   fig = uifigure('Name', 'Properties Window', 'Position', [50 50 350 800]);

   axesFig = figure('Name', 'Network Viewer', ...
       'Position', [400 50 900 750], 'Color', [1 1 1]);
   ax = axes(axesFig, 'Units','normalized',...
       "Position", [0 0 1 1]);

   axis 'off';

   % Set the CloseRequestFcn of both windows to close both figures
   fig.CloseRequestFcn = @closeBothFig;
   axesFig.CloseRequestFcn = @closeBothFig;

   global activeNwk;
   global activeG;
   global activeHandle;
   global activeIdx;

   global largeNwk;

   global tableGrpBoxes;
   global applyBtn;
   global resetBtn;
   global renameBtn;
   global grpTitles;

   largeNwk = 1000;
   G = graph([], []);
   faceProp = [];
   global nodeColor;
   global preColor;
   nodeColor = [0.2 0.2 0.2];

   preColor = [
    1.0, 0.0, 0.0;  % Red
    0.0, 0.0, 1.0;  % Blue
    0.0, 1.0, 0.0;  % Green
    0.0, 1.0, 1.0;  % Cyan
    1.0, 0.0, 1.0;  % Magenta
    0.5, 0.0, 1.0;  % Violet
    0.3, 0.3, 0.3;  % Dark Grey
    0.0, 0.5, 0.0;  % Dark Green
    1.0, 0.5, 0.0;  % Orange
    0.5, 0.0, 0.0;  % Maroon
    ];
    numColors = size(preColor, 1);

   % Plot the graph in a uipanel in the same window as the ui buttons
   %uiplot = uipanel(fig, 'Position', [400 120 750 600]);
   %ax = uiaxes(uiplot, 'Units','normalized',...
   %     "Position", [0 0 1 1]);

   % rotate3d on;
   %view(ax,45,40);
   %colorbar;
   % xlabel(ax,'x (mm)');
   % ylabel(ax,'y (mm)');
   % zlabel(ax,'Cortical Depth (mm)');
   set(ax, 'xtick', [],'xticklabel', [], 'ytick', [],'yticklabel', [], 'ztick', [], 'zticklabel', []);
   initialXLim = [-1 1];
   initialYLim = [-1 1];
   ax.XLim = initialXLim;
   ax.YLim = initialYLim;
   ax.ZLim = [-1, 1];

   % Create a uicontrol listbox (dropdown menu)
   fileDropdown = uicontrol(axesFig, 'Style', 'popupmenu', 'String', ' ', ...
                         'Position', [0 710 900 40], 'Callback', @changeActiveFile);

   %Create tabbed panels (if parent is figure for tabbed group, position should be in percentages)
   tabgp = uitabgroup(fig,"Position",[20 20 300 700]);
   viewTab = uitab(tabgp,"Title", "View", "BackgroundColor", [0.8 0.8 0.8]);
   editTab = uitab(tabgp,"Title", "Edit", "BackgroundColor", [0.8 0.8 0.8]);
   tab3 = uitab(tabgp, "Title","Transform/Scale", "BackgroundColor",[0.8 0.8 0.8]);

   %Create load, clear, save buttons in Properties window
   loadButton = uibutton(fig, 'push', 'Text', 'Load', 'Position', [22, 740, 50, 30], ...
        'ButtonPushedFcn', @loadButtonCb);

   clearButton = uibutton(fig, 'push', 'Text', 'Clear', 'Position', [80, 740, 50, 30], ...
        'ButtonPushedFcn', @clearPlotCb);

   saveButton = uibutton(fig, 'push', 'Text', 'Save', 'Position', [140, 740, 50, 30], ...
       'ButtonPushedFcn', @saveScene);

   snapShotBtn = uibutton(fig, 'push', 'Text', 'Snapshot', 'Position', [200 740 80 30],...
       'ButtonPushedFcn', @snapshotCb);


   %Create first group of checkboes in View tab
   labelsOn = uicheckbox(viewTab, "Text", "labelsOn",...
       "Position",[22 640 70 22], 'ValueChangedFcn', @labelsOnCb);

   directionsOn = uicheckbox(viewTab, "Text", "directionsOn",...
       "Position",[22 620 100 22], 'ValueChangedFcn', @directionsOnCb);

   ptSelect = uicheckbox(viewTab, "Text", "PtSelect",...
       "Position",[22 600 70 22],...
       "ValueChangedFcn", @ptSelectCb);

   toggleCylindersView = uicheckbox(viewTab, "Text", "toggleCylindersView",...
       "Position",[140 640 130 22],...
       "ValueChangedFcn", {@togglePlotCb, []});

   boundingBoxOn = uicheckbox(viewTab, "Text", "BoundingBoxOn",...
       "Position",[140 620 110 22], ...
       "ValueChangedFcn", @boundingBoxCb);
   
   faceSelect = uicheckbox(viewTab, "Text", "faceSelect",...
       "Position",[140 600 80 22],...
       "ValueChangedFcn", @faceSelectCb);

   % %Create transparency textbox in View tab
   % transparencyLabel = uilabel(viewTab, 'Text', 'Transparency',...
   %     'Position', [80, 575, 80, 22]);
   % transparency = uieditfield(viewTab,"numeric",...
   %     "Value", [],...
   %     "Limits",[-5 10],...
   %     "AllowEmpty","on",...
   %     "Position", [165 575 100 22]);

   %Create a button group for Endpoints and Endfaces in View tab
   endpointsGrp = uibuttongroup(viewTab, "Title", "Show EndPoints",...
       "TitlePosition","lefttop",...
       "Position", [20, 510, 260, 80],...
       "BackgroundColor",[0.8 0.8 0.8], ...
       "SelectionChangedFcn", @updateEndPoints);

   endfacesGrp = uibuttongroup(viewTab, "Title", "Show EndFaces",...
       "TitlePosition","lefttop",...
       "Position", [20, 425, 260, 80],...
       "BackgroundColor",[0.8 0.8 0.8], ...
       "SelectionChangedFcn", @updateEndFaces);

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
   editGrp = uipanel(viewTab,...
       "Position", [20, 250, 260, 170],...
       "BackgroundColor",[0.8 0.8 0.8]);

   selectionGrp = uibuttongroup(viewTab, "Title", "Selection",...
       "TitlePosition","lefttop",...
       "Position", [28, 365, 240, 50],...
       "BackgroundColor",[0.8 0.8 0.8], ...
       "SelectionChangedFcn", @updateSelections);

   %Create radio buttons in selection Group Buttongroup
   selectionRb1 = uiradiobutton(selectionGrp, "Text", "Both",...
       'Value', true, "Position", [10 5 50 20]);
   selectionRb2 = uiradiobutton(selectionGrp, 'Text', 'Selections',...
       'Position', [65 5 80 20]);
   selectionRb3 = uiradiobutton(selectionGrp, 'Text', '~Selections',...
       'Position', [150 5 80 20]);
   
   %Create face edit label and edit box
   faceEditLabel = uilabel(viewTab, 'Text', 'faceEdit',...
       'Position', [28 335 50 15]);
   
   faceEditBox = uitextarea(viewTab, "Value", '', ...
       "Position", [80 325 190 35], 'Editable', 'on', ...
       'HorizontalAlignment', 'left', 'WordWrap', 'on');
    
    faceEditBox.Tooltip = sprintf(['Allowed formats:\n' ...
        '- Entries separated by commas.\n' ...
        '- Entries can be:\n' ...
        '  1. Single integers (e.g., ''12,23,18'' for face IDs 12, 23, 18).\n' ...
        '  2. Ranges (e.g., ''18:22'' for face IDs 18, 19, 20, 21, 22).\n' ...
        '  3. Logical conditions:\n' ...
        '        - Symbols: d (diameter), l (face length), f (face ID), g (group ID) ' ...
        '           p1 (inlet point), p2 (outlet point)\n' ...
        '         - Operators: >, <, =\n' ...
        '         - Combine conditions with ''&''.\n' ...
        '         - Example usage: ''d>2&l<10,f>10&f<15,g=13,p1=100''\n' ...
        '              - ''d>2&l<10'' (Faces with diameter > 2 and face length < 10)\n' ...
        '              - ''f>10&f<15'' (Faces with face ID equal to 11,12,13,14)\n' ...
        '              - ''g=13'' (Faces with group ID equal to 13)\n' ...
        '              - ''p1=100''(Faces that have inlet point as 100)\n']);

   %Create point edit label and edit box
   ptEditLabel = uilabel(viewTab, 'Text', 'pointEdit',...
       'Position', [28 290 50 15]);
   
   ptEditBox = uitextarea(viewTab, "Value", '', ...
       "Position", [80 285 190 35], 'Editable', 'on', ...
       'HorizontalAlignment', 'left', 'WordWrap', 'on');


    ptEditBox.Tooltip = sprintf(['Allowed formats:\n' ...
        '- Entries separated by commas.\n' ...
        '- Entries can be:\n' ...
        '  1. Single integers (e.g., ''12,23,18'' for point IDs 12, 23, 18)\n' ...
        '  2. Ranges (e.g., ''18:21'' for point IDs 18, 19, 20, 21)\n' ...
        '  3. Logical conditions:\n' ...
        '        - Symbols: DGi (Indegree of a point), DGo (Outdegree of a point), ' ...
        '           p (point ID), X (X-cordinate of a point) ' ...
        '           Y (Y-cordinate of a point), Z (Z-cordinate of a point)\n' ...
        '         - Operators: >, <, =\n' ...
        '         - Combine conditions with ''&''.\n' ...
        '         - Example usage: ''X<100&X>20,DGi=1&DGo=2,p>7''\n' ...
        '              - ''X<100&X>20'' (Points with x coordinate between 20 and 100)\n' ...
        '              - ''DGi=1&DGo=2'' (Points with 1 indegree and 2 outdegree, bifurcation points)\n' ...
        '              - ''p>7'' (Points with point IDs from 8 to total number of points(np))\n']);

   %Create the Display and Reset button
   displayButton = uibutton(viewTab, 'Text', 'Display',...
       'Position', [30 260 75 20],...
       'ButtonPushedFcn', @updateSelections);

   resetButton = uibutton(viewTab, 'Text', 'Reset',...
       'Position', [115 260 75 20],...
       'ButtonPushedFcn', @resetSelections);

   editButton = uibutton(viewTab, 'Text', 'Edit',...
       'Position', [195 260 75 20],...
       'ButtonPushedFcn', @editSelections);

   %%% BiFurcation ui controls %%%

   % %Create a bifurcation panel
   % bifurcationGrp = uipanel(viewTab,...
   %     "Title", "bifurcationInspection",...
   %     "TitlePosition","lefttop",...
   %     "Position", [20, 165, 260, 80],...
   %     "BackgroundColor",[0.8 0.8 0.8]);
   % 
   % pointEditLabel = uilabel(viewTab, 'Text', 'bifurcationSelection',...
   %     'Position', [25 195 120 20]);
   % 
   % %Create the Display and Reset button
   % displayButton = uibutton(viewTab, 'Text', 'Display',...
   %     'Position', [70 170 70 20],...
   %     'ButtonPushedFcn', @displayButtonCallback);
   % 
   % resetButton = uibutton(viewTab, 'Text', 'ResetBif',...
   %     'Position', [160 170 70 20],...
   %     'ButtonPushedFcn', @resetButtonCallback);


   %Create a tabbed panel with color selections
   colorTab = uitabgroup(viewTab, 'Position', [20, 10, 260, 235]);
   faceGrp = uitab(colorTab, 'Title', 'FaceGroup', 'BackgroundColor', [0.8, 0.8, 0.8], 'Scrollable', 'on');
   propertiesTab = uitab(colorTab, 'Title', 'Properties', 'BackgroundColor', [0.8, 0.8, 0.8], 'Scrollable', 'on');

   % Table to store all the loaded objects
   rendererTable = table('Size', [0, 7], ...
                   'VariableTypes', {'string', 'string', 'cell', 'cell', 'cell', 'cell', 'cell'}, ...
                   'VariableNames', {'fileName', 'type', 'nwkObj', 'plotHandle', 'graphObj', 'boxHandle', 'grpColors'});

   viewTable = table('Size', [0, 4], ...
                    'VariableTypes', {'string', 'string', 'cell', 'cell'}, ...
                    'VariableNames', {'fileName', 'type', 'nwkObj', 'patchObj'});

   warning('off', 'all');

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
    
    function togglePlotCb(~, ~, facesList, collColor)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        if toggleCylindersView.Value            
            if isempty(facesList)
                if ~isempty(activeHandle.UserData(1).groups)
                    groupIds = activeHandle.UserData(1).groups;
                    facesList = find(ismember(activeNwk.faceMx(:, 1), groupIds));
                
                    %elseif ~isempty(activeHandle.UserData(1).selections) 
                    %selections will have hanging points too, then?
                else
                    facesList = (1:activeNwk.nf)';
                end
            end

            if ~isempty(rendererTable.plotHandle{activeIdx})
                delete(rendererTable.plotHandle{activeIdx});
            end

            color = [];
            if nargin > 3 && ~isempty(collColor)
                color = collColor;
            elseif ~isempty(rendererTable.grpColors{activeIdx})
                firstColor = rendererTable.grpColors{activeIdx}.values{1};
                for i = 2:length(rendererTable.grpColors{activeIdx}.keys)
                    if ~isequal(rendererTable.grpColors{activeIdx}.values{i}, firstColor)
                        color = jet(256);
                        break;
                    end
                end
                if isempty(color)
                    color = firstColor;
                end
            else
                color = jet(256);
            end

            hold(ax, 'on');
            [~, activeHandle] = RenderNwkTV(activeNwk, facesList, activeNwk.dia, [], [], [], color);
            colorbar;
            hold(ax, 'off');

            rendererTable.plotHandle{activeIdx} = activeHandle;

            activeHandle.UserData(1).type = 'cylinders';

            labelsOn.Value = false;
            directionsOn.Value = false;

            % Disable datacursor mode if it is set
            if ptSelect.Value
                ptSelect.Value = false;
                ptSelectCb();
            elseif faceSelect.Value
                faceSelect.Value = false;
                faceSelectCb();
            end

        elseif strcmp(activeHandle.UserData(1).type, 'cylinders') && ~toggleCylindersView.Value

            if  ~isempty(ptEditBox.Value{1}) || ~isempty(faceEditBox.Value{1})
                   updateSelections();
            else
                   faceGrpEditCb();
            end
            colorbar('off');
        end
        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

    % Callback for file drop down menu
    function changeActiveFile(~, ~)

        if isequal(fileDropdown.Value, 1) && isequal(fileDropdown.String, ' ')
            return;
        end
    
        activeIdx = fileDropdown.Value;
        activeNwk = rendererTable.nwkObj{activeIdx};
        activeG = rendererTable.graphObj{activeIdx};
        activeHandle = rendererTable.plotHandle{activeIdx};

        % Restore groups and selections 
        initGroupBox();

        if isfield(activeHandle.UserData, 'selections') && ~isempty(activeHandle.UserData(1).selections)
            ptEditBox.Value = activeHandle.UserData(1).selections{1};
            faceEditBox.Value = activeHandle.UserData(1).selections{2};
            if activeHandle.UserData(1).selections{3} == 1
                selectionRb1.Value = true;
            elseif activeHandle.UserData(1).selections{3} == 2
                selectionRb2.Value = true;
            else
                selectionRb3.Value = true;
            end    
        else
            selectionRb2.Value = false;
            selectionRb1.Value = true;
            selectionRb3.Value = false;
    
            faceEditBox.Value = '';
            ptEditBox.Value = '';
            
        end

        reApplyUIOptions();
        initGroupBox();

        updateEndPoints();
        updateEndFaces();

    end

    function loadButtonCb(~, ~)

         [file, path] = uigetfile('*.fMx;*.coll;*.stl', 'Select a file to load');
         if isequal(file, 0) || isequal(path, 0)
              disp('File selection canceled');
              return
         end
         [~, ~, ext] = fileparts(fullfile(path, file));

         fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
         tic;
        
         if strcmp(ext, '.coll')
            fid = fopen(fullfile(path, file), 'r');
            if fid == -1
                disp('Unable to open the collection file.');
                return
            end

            validViews = {'cylinders', 'graph'};
            collData = {};
    
             while ~feof(fid)
                line = fgetl(fid);
                
                paths = regexp(line, 'path=([^, ]+)', 'tokens');
                colors = regexp(line, 'color=([^, ]+)', 'tokens');
                views = regexp(line, 'view=([^, ]+)', 'tokens');
                
                if isempty(paths)
                    disp('Invalid collection file. Format should be path=<absolute-path>\n,color=<color-name>,view=<cylinders/graph>');
                    return
                else
                    if isempty(views) || ~ismember(views{1}{1}, validViews)
                       views{1}{1} = 'graph';
                    end
                    if isempty(colors)
                        colors{1}{1} = 'black';
                    end
                    collData(end+1, :) = {paths{1}{1}, colors{1}{1}, views{1}{1}};
                end
            end

            fclose(fid);
            
            for i = 1:size(collData, 1)
                collFilePath = collData{i, 1};
                loadScene(collFilePath, collData{i, 3}, collData{i, 2});
                fprintf("Loaded nwk : %s\n", collFilePath);

            end

         else
            
             loadScene(fullfile(path, file), 'graph');
             initGroupBox();

         end

         % Reset point and face highlights' UI options
         ptNoneRb1.Value = true;
         facesRb1.Value = true;
 
         selectionRb1.Value = true;
         faceEditBox.Value = '';
         ptEditBox.Value = '';
          
         fileDropdown.String = rendererTable.fileName(:);
         fileDropdown.Value = activeIdx;

         loadTime = toc;
         fprintf("Load time for nwk : %.2f seconds\n", loadTime);
         fig.Pointer = 'arrow';  axesFig.Pointer = 'arrow';
       
    end

    function loadScene(filePath, view, collColor)
        [path, name, ext] = fileparts(filePath);

         if strcmp(ext, '.fMx')
             activeNwk = nwkHelp.load(fullfile(path, name));
             activeIdx = size(rendererTable, 1) + 1;
             rendererTable(activeIdx, 1:3) = {filePath, ext, {activeNwk}};
            
             if activeNwk.nf > largeNwk || activeNwk.np > largeNwk
                  grpIds = selectLoadGrps();
                  facesList = find(ismember(activeNwk.faceMx(:, 1), grpIds));

                  if strcmp(view, 'graph')
                      plotSubsetFacesPts(facesList, []);
                  else
                      toggleCylindersView.Value = true;
                      togglePlotCb([], [], facesList, collColor);
                  end
                  activeHandle.UserData(1).groups = grpIds;
             else
                 if strcmp(view, 'graph')
                     plotGraph();
                 else
                     toggleCylindersView.Value = true;
                     togglePlotCb([], [], (1:activeNwk.nf)', collColor);
                 end
             end

             expandAxesLimits(ax, activeNwk);
             createPngForIco(filePath);
             initGroupBox(collColor);

         elseif strcmp(ext, '.stl')

             stlNwk = nwkConverter.stl2nwk(filePath);
             idx = size(viewTable, 1) + 1;
             viewTable(idx, 1:3) = {filePath, ext, {stlNwk}};
             plotStl(stlNwk);
             expandAxesLimits(ax, stlNwk);

         elseif strcmp(ext, '.msh')

             meshNwk = nwkConverter.mesh2nwk(filePath);
             idx = size(viewTable, 1) + 1;
             viewTable(idx, 1:3) = {filePath, ext, {meshNwk}};
             plotMesh();
             expandAxesLimits(ax, meshNwk);
         end

    end

    function saveScene(~, ~)

        [file, path] = uiputfile('*.coll', 'Save Scene Collection As');
        if isequal(file, 0) || isequal(path, 0)
            disp('Saving canceled.');
            return;
        end

        fid = fopen(fullfile(path, file), 'w');
        if fid == -1
            error('Unable to open or create the file.');
        end
        
        fprintf(fid, '%s\n', rendererTable.fileName{:});
        fclose(fid);
        disp(['Scene collection saved to: ', fullfile(path, file)]);

    end    


    function initGroupBox(collColor)

        delGrpCheckboxes();

        if activeNwk.nf <= 0 % Point cloud 
            return;
        end   

        uniqueGroupIDs = unique(activeNwk.faceMx(:, 1));
        numGrpIds = numel(uniqueGroupIDs);
        tableGrpBoxes = table('Size', [numGrpIds, 3], ...
                   'VariableTypes', {'cell', 'cell', 'cell'}, ...
                   'VariableNames', {'grpBoxHandles', 'colorPickers', 'numFaces'});
        grpTitles = table('Size', [numGrpIds, 1], ...
                   'VariableTypes', {'cell'}, ...
                   'VariableNames', {'title'});
        
        len = 20 * numGrpIds + 5;
        if len < 230
            len = 210;
        end
      
        scroll(faceGrp, 'top');

        colorsExist = false;
        if nargin > 0 && ~isempty(collColor)
             collColor = validateColor(collColor);
             grpColor = configureDictionary("double", "cell");
        elseif isempty(rendererTable.grpColors{activeIdx})
             grpColor = configureDictionary("double", "cell");
             collColor = '';
        else
             colorsExist = true;
        end

        if isfield(activeHandle.UserData, 'groups') && ~isempty(activeHandle.UserData(1).groups)
            groupIds = activeHandle.UserData(1).groups;
        else
            groupIds = uniqueGroupIDs;
        end

        % Titles
        grpTitles.title{1} = uilabel(faceGrp, 'Text', 'Group ID', 'FontWeight', 'bold', 'FontSize', 10, ...
            'HorizontalAlignment', 'left', 'Position', [20, len + 15, 60, 15]);
        grpTitles.title{2} = uilabel(faceGrp, 'Text', 'Color', 'FontWeight', 'bold', 'FontSize', 10, ...
            'HorizontalAlignment', 'left', 'Position', [90, len + 15, 30, 15]);
        grpTitles.title{3} = uilabel(faceGrp, 'Text', 'Faces', 'FontWeight', 'bold', 'FontSize', 10, ...
            'HorizontalAlignment', 'left', 'Position', [130, len + 15, 60, 15]);

        for i = 1:numGrpIds
            isChecked = ismember(uniqueGroupIDs(i), groupIds);

            grpChkBox = uicheckbox(faceGrp, 'Text', num2str(uniqueGroupIDs(i)), ...
               'Value', isChecked, 'Position', [20,  len - i * 20, 60, 20]);

            if colorsExist 
                if isKey(rendererTable.grpColors{activeIdx}, uniqueGroupIDs(i))
                    color = rendererTable.grpColors{activeIdx}{uniqueGroupIDs(i)};
                else  % When network's group ids are edited, useful when new grpid is added
                    colorIdx = mod(i-1, numColors) + 1;
                    rendererTable.grpColors{activeIdx}{uniqueGroupIDs(i)} = preColor(colorIdx, :);
                    color = rendererTable.grpColors{activeIdx}{uniqueGroupIDs(i)};
                end    
            else
                if isempty(collColor)
                    colorIdx = mod(i-1, numColors) + 1;
                    color = preColor(colorIdx, :);
                else
                    color = collColor;
                end
                grpColor(uniqueGroupIDs(i)) = {color};
            end
            
            colorBox = uicolorpicker(faceGrp, 'Value', color, ...
                'Position', [90,  len - i * 20, 30, 20]);

            numFaces = sum(ismember(activeNwk.faceMx(:, 1), uniqueGroupIDs(i)));        
            nfLabel = uilabel(faceGrp, 'Text', sprintf('(%d)', numFaces), 'FontSize', 8, ...
                'Position', [130, len - i * 20, 60, 20]);

            grpChkBox.UserData = i; % table index
            colorBox.UserData = uniqueGroupIDs(i); % group index            
            tableGrpBoxes{i, :} =  {grpChkBox, colorBox, nfLabel};
        end

        applyBtn = uibutton(faceGrp, 'Text', 'Apply', 'FontSize', 10, ...
            'Position', [200, 180, 50, 30], 'ButtonPushedFcn', @faceGrpEditCb);

        resetBtn = uibutton(faceGrp, 'Text', 'Reset', 'FontSize', 10, ...
            'Position', [200, 140, 50, 30], 'ButtonPushedFcn', @resetColors);

        renameBtn = uibutton(faceGrp, 'Text', 'Rename', 'FontSize', 10, ...
            'Position', [200, 100, 50, 30], 'ButtonPushedFcn', @renameGrps);

        if ~colorsExist
            rendererTable.grpColors{activeIdx} = grpColor;
            reColorGrps();
        end

    end


    function clearPlotCb(~, ~)
        objNames = rendererTable.fileName;
        if ~isempty(viewTable)
            viewNames = viewTable.fileName;
            objNames = [objNames , viewNames];
        end
        [selectedIdx, ok] = listdlg('ListString', objNames, 'SelectionMode', 'single',...
            'PromptString', 'Select an object to clear:', 'Name', 'Select Object', 'ListSize', [300, 100]);        
    
        if ok
            if selectedIdx > size(rendererTable, 1)
                idx = selectedIdx - size(rendererTable, 1);
                delete(viewTable.patchObj{idx});
                viewTable(idx, :) = [];
                return;
            end

            delete(rendererTable.plotHandle{selectedIdx});
            rendererTable(selectedIdx, :) = [];

            fileDropdown.String = rendererTable.fileName(:);

            if activeIdx == selectedIdx
                if size(rendererTable, 1) > 0
                    fileDropdown.Value = size(rendererTable, 1);
                    changeActiveFile();
                else
                    fileDropdown.String = ' ';
                    delGrpCheckboxes();
                    return;
                end
            elseif activeIdx > selectedIdx
                activeIdx = activeIdx - 1;
                fileDropdown.Value = activeIdx;
                activeNwk = rendererTable.nwkObj{activeIdx};
                activeG = rendererTable.graphObj{activeIdx};
                activeHandle = rendererTable.plotHandle{activeIdx};
            end
        end
    end


    function plotGraph(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        if directionsOn.Value && activeNwk.nf
            G = digraph(activeNwk.faceMx(:, 2), activeNwk.faceMx(:, 3), 1:activeNwk.nf);
            type = 'digraph';
        elseif activeNwk.nf 
            G = graph(activeNwk.faceMx(:, 2), activeNwk.faceMx(:, 3), 1:activeNwk.nf);
            type = 'graph';
        else % point cloud
            G = graph([], []);
            G = addnode(G, activeNwk.np);
            type = 'graph';
        end

        if ~isempty(rendererTable.plotHandle{activeIdx})
            delete(rendererTable.plotHandle{activeIdx});
        end

        G.Nodes = table(activeNwk.ptCoordMx(:, 1), activeNwk.ptCoordMx(:, 2), activeNwk.ptCoordMx(:, 3),...
           'VariableNames', {'X', 'Y', 'Z'});
        G.Nodes.Labels(:) = 1:activeNwk.np;

        hold(ax, "on");
        activeHandle = plot(G, 'XData', G.Nodes.X, 'YData', G.Nodes.Y, ...
            'ZData', G.Nodes.Z, 'NodeColor', nodeColor,...
            'EdgeColor', '[0 0 0.5]', 'NodeLabel', {}, 'MarkerSize', 2, 'LineWidth', 2, 'Parent', ax);
        hold(ax, "off");

        activeHandle.UserData = struct('type', '', 'selections', {}, 'groups', []);
        activeHandle.UserData(1).type = type;
        activeG = G;
        rendererTable(activeIdx, 4:5) = {{activeHandle}, {activeG}};

        if labelsOn.Value
            labelsOnCb();
        end

         % Disable datacursor mode if it is set
        if ptSelect.Value
            ptSelect.Value = false;
            ptSelectCb();
        elseif faceSelect.Value
            faceSelect.Value = false;
            faceSelectCb();
        end

        drawnow;

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end

    function plotStl(stlNwk)
        
        hold(ax, "on");
        stlHandle = patch(ax, 'Faces', stlNwk.faceMx3, 'Vertices', stlNwk.ptCoordMx, ...
            'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.75 0.75 0.75]);
        hold(ax, "off");

        idx = size(viewTable, 1);
        viewTable(idx, 4) = {{stlHandle}};

    end    

    function expandAxesLimits(ax, Nwk)
        maxLims = max(Nwk.ptCoordMx);
        minLims = min(Nwk.ptCoordMx);
        padding = 0.2 * (maxLims - minLims);

        upperLims = maxLims + padding;
        lowerLims = minLims - padding;

        if ~isempty(Nwk.dia)
            maxDia = max(Nwk.dia);
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
        saveas(axesFig, filepath, 'png'); % the figure view
        %exportgraphics(ax, filepath, 'ContentType', 'image', 'Resolution', 300); %the axes view
    end

    function writeToReport(text, ptList, faceList)
        fid = fopen('draw_report.txt', 'a');        
        if fid == -1
            error('Unable to open or create report.txt');
        end

        currentTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
        fprintf(fid, '\n%s: %s\n', char(currentTime), text);
        if ~isempty(ptList)
            for i=1:length(ptList)
                fprintf(fid, '%s: %s\n', num2str(ptList(i)), num2str(activeNwk.ptCoordMx(ptList(i), :)));
            end
        end

        if ~isempty(faceList)
            for i=1:length(faceList)
                fprintf(fid, '%s: %s\n', num2str(faceList(i)), num2str(activeNwk.faceMx(faceList(i), :)));
            end
        end
        
    end

    function boundingBoxCb(~, ~)

        if  boundingBoxOn.Value
        
            % Define padding percentage
            padding = 0.1;
            
            % Determine bounding box limits
            minX = min(activeNwk.ptCoordMx(:, 1));
            maxX = max(activeNwk.ptCoordMx(:, 1));
            minY = min(activeNwk.ptCoordMx(:, 2));
            maxY = max(activeNwk.ptCoordMx(:, 2));
            minZ = min(activeNwk.ptCoordMx(:, 3));
            maxZ = max(activeNwk.ptCoordMx(:, 3));
            
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
            bbHandle = plot(bbGraph, 'XData', vertices(:, 1), 'YData', vertices(:, 2),...
                'ZData', vertices(:, 3), 'EdgeColor', 'k',... 
                'NodeColor', '[0.95 0.95 0.95]', 'LineWidth', 2, 'EdgeAlpha', 0.1, ...
                'NodeLabel', {});
            hold(ax, "off");
            rendererTable.boxHandle{activeIdx} = bbHandle;

        else
            delete(rendererTable.boxHandle{activeIdx});
        end

    end

    function labelsOnCb(~, ~)

        % Always shows only 100 labels
        tic;
        ptThreshold = 100;
        faceThreshold = 100;
        isLargeNwk = activeNwk.np > ptThreshold || activeNwk.nf > faceThreshold;

        if labelsOn.Value

            stepPt = round(activeNwk.np / 100); 
            stepFace = round(activeNwk.nf / 100);

            ptLabels = repmat({''}, size(activeG.Nodes, 1), 1);
            faceLabels = repmat({''}, size(activeG.Edges, 1), 1);

            if isLargeNwk
                ptLabels(1:stepPt:end) = strcat('P', arrayfun(@num2str, activeG.Nodes.Labels(1:stepPt:end), 'UniformOutput', false));
                faceLabels(1:stepFace:end) = strcat('F', arrayfun(@num2str, activeG.Edges.Weight(1:stepFace:end), 'UniformOutput', false));
            else
                ptLabels = strcat('P', arrayfun(@num2str, activeG.Nodes.Labels, 'UniformOutput', false));
                faceLabels = strcat('F', arrayfun(@num2str, activeG.Edges.Weight, 'UniformOutput', false));
            end
            
            set(activeHandle, 'NodeLabel', ptLabels, 'EdgeLabel', faceLabels);
        else
            set(activeHandle, 'NodeLabel', '', 'EdgeLabel', '');
        end
        elapsedTime = toc;
        fprintf('Time taken for labelling: %.2f seconds\n', elapsedTime);

    end

    function directionsOnCb(~, ~)
        if directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'graph') || ~directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'digraph')
            plotGraph();
            reColorGrps();
            updateEndPoints();
            updateEndFaces();
        elseif directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'subgraph') || ~directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'disubgraph')

            if isfield(activeHandle.UserData, 'groups') && ~isempty(activeHandle.UserData(1).groups)
                  faceGrpEditCb();
            elseif  ~isempty(ptEditBox.Value) || ~isempty(faceEditBox.Value)
                  updateSelections();
            end

        end    
    end    


    function updateEndPoints(~, ~)

        if ~contains(activeHandle.UserData(1).type, 'graph') || contains(activeHandle.UserData(1).type, 'subgraph')
            return;
        end

        [inlet, outlet] = nwkHelp.findBoundaryNodes(activeNwk);       

        if strcmp(endpointsGrp.SelectedObject.Text, 'None')
            highlight(activeHandle, inlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            highlight(activeHandle, outlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            if ~labelsOn.Value
                set(activeHandle, 'NodeLabel', {});
            end
        elseif strcmp(endpointsGrp.SelectedObject.Text, 'InletPoints')
            highlight(activeHandle, inlet, 'NodeColor', 'red', 'MarkerSize', 8);
            highlight(activeHandle, outlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            selectionLabels(inlet, []);
        elseif strcmp(endpointsGrp.SelectedObject.Text, 'OutletPoints')     
            highlight(activeHandle, outlet, 'NodeColor', 'blue', 'MarkerSize', 8); 
            highlight(activeHandle, inlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            selectionLabels(outlet, []);
        elseif strcmp(endpointsGrp.SelectedObject.Text, 'All EndPoints')
            highlight(activeHandle, inlet, 'NodeColor', 'red', 'MarkerSize', 8);
            highlight(activeHandle, outlet, 'NodeColor', 'blue', 'MarkerSize', 8);
            selectionLabels([inlet, outlet], []);
        end

    end

    function updateEndFaces(~, ~)

        if ~contains(activeHandle.UserData(1).type, 'graph') || contains(activeHandle.UserData(1).type, 'subgraph')
            return;
        end

        set(activeHandle, 'LineWidth', 2);
        reColorGrps();

        [inlet, outlet] = nwkHelp.findBoundaryFaces(activeNwk);

        if strcmp(endfacesGrp.SelectedObject.Text, 'None')
            
            if ~labelsOn.Value
                set(activeHandle, 'EdgeLabel', {}); 
            end

        elseif strcmp(endfacesGrp.SelectedObject.Text, 'InletFaces')

            highlight(activeHandle, activeNwk.faceMx(inlet, 2),...
             activeNwk.faceMx(inlet, 3), 'EdgeColor', 'red', 'LineWidth', 4);

            selectionLabels([], inlet);
       
        elseif strcmp(endfacesGrp.SelectedObject.Text, 'OutletFaces')
        
            highlight(activeHandle, activeNwk.faceMx(outlet, 2),...
             activeNwk.faceMx(outlet, 3), 'EdgeColor', 'blue', 'LineWidth', 4);

            selectionLabels([], outlet);
        
        elseif strcmp(endfacesGrp.SelectedObject.Text, 'All EndFaces')
           
            highlight(activeHandle, activeNwk.faceMx(inlet, 2),...
             activeNwk.faceMx(inlet, 3), 'EdgeColor', 'red', 'LineWidth', 4);

            highlight(activeHandle, activeNwk.faceMx(outlet, 2),...
             activeNwk.faceMx(outlet, 3), 'EdgeColor', 'blue', 'LineWidth', 4);

            selectionLabels([], [inlet, outlet]);
        end

    end

    set(axesFig, 'WindowButtonDownFcn', @mouseClickCb);
    global initialMousePos;
    
    function mouseClickCb(src, ~)

        if strcmp(src.SelectionType, 'normal') % Right mouse click
            set(axesFig, 'WindowButtonMotionFcn', @rotateCb);
        elseif strcmp(src.SelectionType, 'alt') % Left mouse click
            set(axesFig, 'WindowButtonMotionFcn', @moveHorizVertCb);
        end
        
        set(axesFig, 'WindowButtonUpFcn', @stopMovingCb);

    end

    function stopMovingCb(~, ~)
        set(axesFig, 'WindowButtonMotionFcn', '');
        set(axesFig, 'WindowButtonUpFcn', '');
        initialMousePos = [];        
    end

    % Assign the callback function to the mouse scroll wheel event
    set(axesFig, 'WindowScrollWheelFcn', @camZoomCb);

    
    % Move camera horizantally and vertically
    function moveHorizVertCb(src, ~)
        
        if isempty(initialMousePos)
            initialMousePos = get(src, 'CurrentPoint');
            return;
        end
        
        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        currentMousePos = get(src, 'CurrentPoint');
        dx = currentMousePos(1) - initialMousePos(1);
        dy = currentMousePos(2) - initialMousePos(2);
        camdolly(ax, -dx, -dy, 0, 'movetarget', 'pixels');
            
         % Update initial mouse position for next callback
        initialMousePos = currentMousePos;


        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end
    
    
    % Rotate the camera
    function rotateCb(src, ~)

       fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
       
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


       fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end
    
    minZoomDist = 1;
    maxZoomDist = 100000;

    % Zoom camera in and out
    function camZoomCb(~, event)
        % Scroll distance is +ve for scrolling up, -ve for scrolling down
        scrollDist = event.VerticalScrollCount;

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
    
        % Fraction of total distance to move the camera
        fraction = 0.1;
        
        camPos = get(ax, 'CameraPosition');
        camTarget = get(ax, 'CameraTarget');
        newCamPos = camPos - scrollDist * fraction * (camPos - camTarget);

        
        newZoomDist = norm(newCamPos - camTarget);
        if newZoomDist >= minZoomDist && newZoomDist <= maxZoomDist
            set(ax, 'CameraViewAngleMode', 'manual', 'CameraPosition', newCamPos);
        end
       
        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

    % Callback function for the checkbox
    function faceSelectCb(~, ~)

        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end

        dcm_obj = datacursormode(axesFig);
        if ptSelect.Value
            ptSelect.Value = false;
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
        end
        if faceSelect.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @highlightEdgesFromNearestNode);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2, 'NodeLabel', {}, 'EdgeLabel', {});
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            set(activeHandle, 'LineWidth', 2);
            reColorGrps();
            if labelsOn.Value
                labelsOnCb();
            end
        end
    end

    function txt = highlightEdgesFromNearestNode(~, event)

         ptCoords = event.Position;
         activeG = rendererTable.graphObj{activeIdx};
         ptRow = find(activeG.Nodes.X == ptCoords(1) & activeG.Nodes.Y == ptCoords(2) & activeG.Nodes.Z == ptCoords(3));
         ptIdx = activeG.Nodes.Labels(ptRow);
                  
         faceRows = find(activeG.Edges.EndNodes(:, 1) == ptRow | activeG.Edges.EndNodes(:, 2) == ptRow);
         faceIdx = activeG.Edges.Weight(faceRows);

         set(activeHandle, 'LineWidth', 2);
         reColorGrps();

         highlight(activeHandle, activeG.Edges.EndNodes(faceRows, 1), activeG.Edges.EndNodes(faceRows, 2), ...
             'EdgeColor', 'red', 'LineWidth', 4);

         writeToReport('Selected faces: ', [], faceIdx);
  
         txt=['p' num2str(ptIdx)];

         selectionLabels([], faceIdx);
    end

   
    % Callback function for the checkbox
    function ptSelectCb(~, ~)
        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end
 
        dcm_obj = datacursormode(axesFig);
        if faceSelect.Value
            faceSelect.Value = false;
            set(activeHandle, 'LineWidth', 2);
            reColorGrps();
        end
        if ptSelect.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @selectPt);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2, 'NodeLabel', {}, 'EdgeLabel', {});
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
            if labelsOn.Value
                labelsOnCb();
            end
        end
    end

    function selectionLabels(ptsIdx, facesIdx)
        activeG = rendererTable.graphObj{activeIdx};

        if ~isempty(ptsIdx)
            ptLabels = strings(height(activeG.Nodes), 1);
            for i = 1:length(ptsIdx)
                ptIdx = ptsIdx(i);
                matchingPt = find(activeG.Nodes.Labels == ptIdx);
                ptLabels(matchingPt) = ['P' num2str(ptIdx)];
            end
            activeHandle.NodeLabel = ptLabels;
        end

        if ~isempty(facesIdx)
            faceLabels = strings(height(activeG.Edges), 1);
            for i = 1:length(facesIdx)
                faceIdx = facesIdx(i);
                matchingFace = find(activeG.Edges.Weight == faceIdx);
                faceLabels(matchingFace) = ['F' num2str(faceIdx)];
            end
            activeHandle.EdgeLabel = faceLabels;
        end
    end    


    function txt = selectPt(~, event)
         ptCoords = event.Position;

         activeG = rendererTable.graphObj{activeIdx};
         ptRow = find(activeG.Nodes.X == ptCoords(1) & activeG.Nodes.Y == ptCoords(2) & activeG.Nodes.Z == ptCoords(3));
         ptIndex = activeG.Nodes.Labels(ptRow);

         set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
         highlight(activeHandle, ptRow, 'NodeColor', 'red', 'MarkerSize', 8);
         
         writeToReport('Selected points: ', ptIndex, []);

         txt = ['Node ', num2str(ptIndex)];
    end

    function updateSelections(~, ~)


        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        ptSelections = ptEditCb();
        faceSelections = faceEditCb();
        
        if selectionRb2.Value
            
            plotSubsetFacesPts(faceSelections, ptSelections);
            reColorGrps();

            try
                activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), 2};
                activeHandle.UserData(2).groups = [];
            catch ME 
            end

        elseif selectionRb3.Value
            
            ptSelections = setdiff(1:activeNwk.np, ptSelections)';
            faceSelections = setdiff(1:activeNwk.nf, faceSelections)';

            plotSubsetFacesPts(faceSelections, ptSelections);
            reColorGrps();

            try
                activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), 3};
                activeHandle.UserData(2).groups = [];
            catch ME
            end

        else    

            % End points/faces highlights will be gone

            plotGraph();

            % Color everything black, except the green highlights
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
            set(activeHandle, 'EdgeColor', 'black', 'LineWidth', 2);

            highlight(activeHandle, ptSelections, 'NodeColor', 'green', 'MarkerSize', 8);
            faceRows = find(ismember(activeG.Edges.Weight(:), faceSelections));
            highlight(activeHandle, activeG.Edges.EndNodes(faceRows, 1),...
                activeG.Edges.EndNodes(faceRows, 2), 'EdgeColor', 'green', 'LineWidth', 4);

            activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), 1};
            activeHandle.UserData(2).groups = [];

        end

        if ~isempty(ptSelections) || ~isempty(faceSelections)
            writeToReport('Selected points and faces: ', ptSelections, faceSelections);
        end

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

    function resetSelections(~, ~)
        selectionRb2.Value = false;
        selectionRb1.Value = true;
        selectionRb3.Value = false;

        faceEditBox.Value = '';
        ptEditBox.Value = '';
        
        if contains(activeHandle.UserData(1).type, 'subgraph')
            plotGraph(); 
        end
        % elseif strcmp(activeHandle.UserData.type, 'graph') || strcmp(activeHandle.UserData.type, 'digraph')
        %    set(activeHandle, 'NodeColor', 'k', 'MarkerSize', 2);
        %    set(activeHandle, 'LineWidth', 2);
        %    reColorGrps();
        % end

        reApplyHighlights();
        
    end

    function editSelections(~, ~)

        ptSelections = ptEditCb();
        faceSelections = faceEditCb();
        
        editFig = uifigure('WindowStyle', 'alwaysontop', 'Name', 'Edit Faces', ...
            'Position', [500, 300, 500, 800], 'Scrollable', 'on');

        % Display the matrix
        faceTmp = [num2cell(int32(activeNwk.faceMx(faceSelections, 1))), ...
            num2cell(int32(activeNwk.faceMx(faceSelections, 2))), ...
            num2cell(int32(activeNwk.faceMx(faceSelections, 3))), ...
            num2cell(double(activeNwk.dia(faceSelections)))];

        ptTmp = activeNwk.ptCoordMx(ptSelections, 1:3);

        uilabel(editFig, 'Text', 'Face Selection Matrix: ', 'Position', [20, 760, 460, 20]);

        faceTable = uitable(editFig, 'Data', faceTmp, 'Position', [20, 600, 460, 160], ...
            'ColumnEditable', true, 'ColumnName', {'Group ID' ; 'Pt Index1' ; 'Pt Index2' ; 'Diameter'}, ...
            'ColumnWidth', 'auto', 'RowName', {faceSelections}, 'RowStriping', 'on');

        uilabel(editFig, 'Text', 'Point Selection Matrix: ', 'Position', [20, 560, 460, 20]);

        ptTable = uitable(editFig, 'Data', ptTmp, 'Position', [20, 400, 460, 160], ...
           'ColumnEditable', true, 'ColumnName', {'X', 'Y', 'Z'}, ...
           'RowName', {ptSelections}, 'RowStriping', 'on');

        uilabel(editFig, 'Text', 'Face Selection Indexes: ', 'Position', [20, 360, 460, 20]);

        faceSelectionField = uitextarea(editFig, 'Value', strjoin(string(faceSelections), ','), ...
        'Position', [20, 240, 460, 120], 'Editable', 'on', 'HorizontalAlignment', 'left', 'WordWrap', 'on');

        uilabel(editFig, 'Text', 'Point Selection Indexes: ', 'Position', [20, 200, 460, 20]);

        ptSelectionField = uitextarea(editFig, 'Value', strjoin(string(ptSelections), ','), ...
        'Position', [20, 80, 460, 120], 'Editable', 'on', 'HorizontalAlignment', 'left', 'WordWrap', 'on');

        % Create Save button
        applyEditsBtn = uibutton(editFig, 'Text', 'Apply', 'Position', [50, 30, 80, 30], ...
            'ButtonPushedFcn', @(~, ~) applyEditCb());

        % Create Cancel button
        cancelBtn = uibutton(editFig, 'Text', 'Cancel', 'Position', [150, 30, 80, 30], ...
            'ButtonPushedFcn', @(~, ~) close(editFig));

        % Nested function to save changes
        function applyEditCb()
            faceEditedData = faceTable.Data;

            activeNwk.faceMx(faceSelections, 1) = cell2mat(faceEditedData(:, 1));
            activeNwk.faceMx(faceSelections, 2) = cell2mat(faceEditedData(:, 2));
            activeNwk.faceMx(faceSelections, 3) = cell2mat(faceEditedData(:, 3));
            activeNwk.dia(faceSelections) = cell2mat(faceEditedData(:, 4));

            ptEditedData = ptTable.Data;
            activeNwk.ptCoordMx(ptSelections, 1:3) = ptEditedData(:, 1:3);

            updateSelections();
            initGroupBox();

            % % reApplyUIOptions();
            % reApplyHighlights();

            close(editFig);
        end

    end    

    function [ptsList] = ptEditCb()
        input_str = strjoin(ptEditBox.Value, '');
        input_str = strrep(input_str, ' ', '');  % Remove whitespace
        input_values = strsplit(input_str, ',');  % Split by comma
        
        ptsList = [];        
        for i = 1:numel(input_values)
            value = input_values{i};
            
            if contains(value, '&')
                conditions = strsplit(value, '&');
                tempPtsList = 1:activeNwk.np;
                for j = 1:numel(conditions)
                    condition = conditions{j};
                    tempPtsList = intersect(tempPtsList, parsePtCondition(condition));
                end
                ptsList = union(ptsList, tempPtsList);
            else
                ptsList = union(ptsList, parsePtCondition(value));
            end
        end
    
        if ~isempty(ptsList)
            ptsList = sort(ptsList, 1);
        end
    end

    function [faceList] = faceEditCb()

        input_str = strjoin(faceEditBox.Value, '');
        input_str = strrep(input_str, ' ', '');
        input_values = strsplit(input_str, ',');
        
        faceList = [];
        
        for i = 1:numel(input_values)
            value = input_values{i};
            
            if contains(value, '&')
                conditions = strsplit(value, '&');
                tempFaceList = 1:activeNwk.nf;
                for j = 1:numel(conditions)
                    condition = conditions{j};
                    tempFaceList = intersect(tempFaceList, parseFaceCondition(condition));
                end
                faceList = union(faceList, tempFaceList);
            else
                faceList = union(faceList, parseFaceCondition(value));
            end
        end

        if ~isempty(faceList)
            faceList = sort(faceList, 1);
        end
    end

    function faceGrpEditCb(~, ~)

        % Color the unchecked group faces with white color
        % Con: hanging node remaining

        % grpId = str2double(src.Text);
        % tableIdx = src.UserData;
        % 
        % facesList = find(ismember(activeNwk.faceMx(:, 1), grpId));
        % 
        % if src.Value
        %     grpColor = tableGrpBoxes.colorPickers{tableIdx}.Value;
        %     highlight(activeHandle, activeNwk.faceMx(facesList, 2),...
        %         activeNwk.faceMx(facesList, 3), 'EdgeColor', grpColor);
        % else
        %     highlight(activeHandle, activeNwk.faceMx(facesList, 2),...
        %         activeNwk.faceMx(facesList, 3), 'EdgeColor', 'white');
        %     set(tableGrpBoxes.colorPickers{tableIdx}, 'Value', 'white');
        % end
 
        checkedGroupIDs = [];
        for i = 1:size(tableGrpBoxes, 1)
             if tableGrpBoxes.grpBoxHandles{i}.Value
                 groupID = str2double(tableGrpBoxes.grpBoxHandles{i}.Text);
                 checkedGroupIDs = [checkedGroupIDs, groupID];
             end
         end

        facesList = find(ismember(activeNwk.faceMx(:, 1), checkedGroupIDs));

        if size(facesList, 1) == activeNwk.nf

             if toggleCylindersView.Value
                 togglePlotCb([], [], (1:activeNwk.nf)');
             else
                plotGraph();
                reColorGrps();
                updateEndPoints();
                updateEndFaces();
             end
        else
             if toggleCylindersView.Value
                 togglePlotCb([], [], facesList);
             else
                plotSubsetFacesPts(facesList, []);
                reColorGrps();
             end

            if selectionRb1.Value
                val = 1;
            elseif selectionRb2.Value    
                val = 2;
            else
                val = 3;
            end
            try
                activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), val};
                activeHandle.UserData(1).groups = checkedGroupIDs;
            catch ME
            end
 
        end

        resetOnRedraw();
        
    end

    function colorGrpEditCb(src, ~)

        grpId = src.UserData;
        facesList = find(ismember(activeNwk.faceMx(:, 1), grpId));
        faceRows = find(ismember(activeG.Edges.Weight(:), facesList));

        % set(activeHandle, 'EdgeColor', 'k', 'LineWidth', 2);

        rendererTable.grpColors{activeIdx}{grpId} = src.Value;

        highlight(activeHandle, activeG.Edges.EndNodes(faceRows, 1),...
            activeG.Edges.EndNodes(faceRows, 2), 'EdgeColor', src.Value);

        % Works only for whole graph, not for subG graph

        % grpId = src.UserData;
        % facesList = find(ismember(activeNwk.faceMx(:, 1), grpId));
        % 
        % highlight(activeHandle, activeNwk.faceMx(facesList, 2),...
        %      activeNwk.faceMx(facesList, 3), 'EdgeColor', src.Value);

    end


    function plotSubsetFacesPts(facesList, ptsList)

            uniquePts = [];

            fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

            if directionsOn.Value
                subG = digraph([], []);
                type = 'disubgraph';
            else
                subG = graph([], []);
                type = 'subgraph';
            end

            if ~isempty(facesList)
                uniquePts = unique(activeNwk.faceMx(facesList, 2:3));
                newFaces = zeros(size(facesList, 1), 3);
                indexMap = containers.Map(uniquePts, 1:length(uniquePts));
                for i = 1:numel(facesList)
                      newFaces(i, :) = [indexMap(activeNwk.faceMx(facesList(i), 2)),...
                          indexMap(activeNwk.faceMx(facesList(i), 3)), facesList(i)];
                end

                if directionsOn.Value
                    subG = digraph(newFaces(:, 1), newFaces(:, 2), newFaces(:, 3));
                else    
                    subG = graph(newFaces(:, 1), newFaces(:, 2), newFaces(:, 3));
                end

                subG.Nodes.X = activeNwk.ptCoordMx(uniquePts, 1);
                subG.Nodes.Y = activeNwk.ptCoordMx(uniquePts, 2);
                subG.Nodes.Z = activeNwk.ptCoordMx(uniquePts, 3);
                subG.Nodes.Labels = uniquePts(:);
            end

            if ~isempty(ptsList)
                diffPtsList = setdiff(ptsList, uniquePts);
                subG = addnode(subG, size(diffPtsList, 1));
                if isempty(uniquePts)
                    np = 0;
                else
                    np = size(uniquePts, 1);
                end

                for i = 1:length(diffPtsList)
                    idx = np + i;
                    subG.Nodes{idx, {'X', 'Y', 'Z'}} = activeNwk.ptCoordMx(diffPtsList(i), :);
                    subG.Nodes.Labels(idx) = diffPtsList(i);
                end
            end

            hold(ax, "on");

            if ~isempty(rendererTable.plotHandle{activeIdx})
                delete(rendererTable.plotHandle{activeIdx});
            end
            
            if ~isempty(subG.Nodes)
                activeHandle = plot(ax, subG, 'XData', subG.Nodes.X, ...
                    'YData', subG.Nodes.Y, 'ZData', subG.Nodes.Z, ...
                     'NodeColor', nodeColor, 'EdgeColor', 'k', 'NodeLabel', {}, ...
                     'MarkerSize', 2, 'LineWidth', 2) ;
                activeHandle.UserData = struct('type', '', 'selections', {}, 'groups', []);         
                activeHandle.UserData(1).type = type;


                activeG = subG;
                rendererTable{activeIdx, 4} = {activeHandle};
                rendererTable{activeIdx, 5} = {activeG};

                if labelsOn.Value
                    labelsOnCb();
                end
            end
            hold(ax, "off");

            activeG = subG;
            rendererTable{activeIdx, 4} = {activeHandle};
            rendererTable{activeIdx, 5} = {activeG};

            % Disable datacursor mode if it is set
            if ptSelect.Value
                ptSelect.Value = false;
                ptSelectCb();
            elseif faceSelect.Value
                faceSelect.Value = false;
                faceSelectCb();
            end

            drawnow;
            fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

   function delGrpCheckboxes()
       
        % Check if the tableGrpBoxes exists and is not empty
        if exist('tableGrpBoxes', 'var') && ~isempty(tableGrpBoxes)
            for i = 1:height(tableGrpBoxes)
                delete(tableGrpBoxes.grpBoxHandles{i});
                delete(tableGrpBoxes.colorPickers{i});
                delete(tableGrpBoxes.numFaces{i});
            end
        end
        delete(applyBtn); delete(resetBtn); delete(renameBtn);
        if exist('grpTitles', 'var') && ~isempty(grpTitles)
            delete(grpTitles.title{1}); delete(grpTitles.title{2}); delete(grpTitles.title{3});
        end
   end

    % Create a small PNG file to be viewed as ico file
    function createPngForIco(filePath)
        [path, name, ~] = fileparts(filePath);

        pngName = fullfile(path, [name, '.png']);

        if ~exist(pngName, 'file')

            tempFig = figure('Visible', 'off');
            set(tempFig, 'Position', [0, 0, 128, 128]);
            axCopy = copyobj(ax, tempFig);

            for i=1:size(axCopy.Children, 1)
                if isa(axCopy.Children(i), 'matlab.graphics.chart.primitive.GraphPlot')
                    axCopy.Children(i).NodeLabel = {};
                    axCopy.Children(i).EdgeLabel = {};
                end
            end

            frame = getframe(axCopy);
            imwrite(frame.cdata, pngName, 'png');
            
            close(tempFig);
            disp(['Created a PNG file for the loaded file: ', pngName]);
        end
    end
        
    function reColorGrps()

       if strcmp(activeHandle.UserData(1).type, 'cylinders')
           return
       end

       for i = 1:size(tableGrpBoxes, 1)
             if tableGrpBoxes.grpBoxHandles{i}.Value 
                colorGrpEditCb(tableGrpBoxes.colorPickers{i});
             end
       end

    end

    function indices = parseFaceCondition(condition)
        indices = [];
        if contains(condition, ':')
            range_values = str2num(condition);
            indices = range_values;
        else
            operator = '';
            if contains(condition, '>')
                operator = '>';
                value = str2double(condition(strfind(condition, '>') + 1:end));
            elseif contains(condition, '<')
                operator = '<';
                value = str2double(condition(strfind(condition, '<') + 1:end));
            elseif contains(condition, '=')
                operator = '=';
                value = str2double(condition(strfind(condition, '=') + 1:end));
            end
            
            if startsWith(condition, 'f')
                if strcmp(operator, '>')
                    indices = (value+1):activeNwk.nf;
                elseif strcmp(operator, '<')
                    indices = 1:(value-1);
                end

            elseif any(startsWith(condition, {'d', 'l', 'g', 'p1', 'p2'}))

                 if strcmp(condition(1), 'd')
                    searchCol = activeNwk.dia;
                 elseif strcmp(condition(1), 'l')
                    if ~isfield(activeNwk, 'faceLen')
                        activeNwk.faceLen = calculateLengths();
                    end
                    searchCol = activeNwk.faceLen;     
                 elseif strcmp(condition(1), 'g')
                    searchCol = activeNwk.faceMx(:, 1);
                 elseif strcmp(condition(1:2), 'p1')
                    searchCol = activeNwk.faceMx(:, 2);
                 elseif strcmp(condition(1:2), 'p2')
                    searchCol = activeNwk.faceMx(:, 3);
                 end
          
                 if strcmp(operator, '=')
                    indices = find(searchCol == value);
                 elseif strcmp(operator, '>')
                    indices = find(searchCol > value);
                 elseif strcmp(operator, '<')
                    indices = find(searchCol < value);
                 end

            else

                index = str2double(condition);
                if ~isnan(index) && index >= 1 && index <= activeNwk.nf
                    indices = index;
                elseif ~isempty(condition)
                    disp(['Invalid input: ', condition]);
                end
            end
        end
    end

    function lengths = calculateLengths()
        numFaces = size(activeNwk.faceMx, 1);
        lengths = zeros(numFaces, 1);
        for k = 1:numFaces
            pt1 = activeNwk.ptCoordMx(activeNwk.faceMx(k, 2), :);
            pt2 = activeNwk.ptCoordMx(activeNwk.faceMx(k, 3), :);
            lengths(k) = sqrt(sum((pt1 - pt2).^2));
        end
    end

    function indices = parsePtCondition(condition)
        indices = [];
        if contains(condition, ':')
            range_values = str2num(condition);
            indices = range_values;
        else
            operator = '';
            if contains(condition, '>')
                operator = '>';
                value = str2double(condition(strfind(condition, '>') + 1:end));
            elseif contains(condition, '<')
                operator = '<';
                value = str2double(condition(strfind(condition, '<') + 1:end));
            elseif contains(condition, '=')
                operator = '=';
                value = str2double(condition(strfind(condition, '=') + 1:end));
            end
            
            if startsWith(condition, 'p')

                if strcmp(operator, '>')
                    indices = (value+1):activeNwk.np;
                elseif strcmp(operator, '<')
                    indices = 1:(value-1);
                elseif contains(condition, '%')
                    indices = value:value:activeNwk.np;
                end

            elseif any(startsWith(condition, {'X', 'Y', 'Z', 'DGi', 'DGo'}))

                if strcmp(condition(1), 'X')              
                    searchCol = activeNwk.ptCoordMx(:, 1);                
                elseif strcmp(condition(1), 'Y')                    
                    searchCol = activeNwk.ptCoordMx(:, 2);
                elseif strcmp(condition(1), 'Z')
                    searchCol = activeNwk.ptCoordMx(:, 3);
                elseif strcmp(condition(1:3), 'DGi')
                    if ~isfield(activeNwk, 'inDeg')
                        [activeNwk.inDeg, activeNwk.outDeg] = calculateInOutDegree();
                    end
                    searchCol = activeNwk.inDeg;
                elseif strcmp(condition(1:3), 'DGo')
                    if ~isfield(activeNwk, 'outDeg')
                        [activeNwk.inDeg, activeNwk.outDeg] = calculateInOutDegree();
                    end
                    searchCol = activeNwk.outDeg;
                end

                if strcmp(operator, '=')
                    indices = find(searchCol == value);
                elseif strcmp(operator, '>')
                    indices = find(searchCol > value);
                elseif strcmp(operator, '<')
                    indices = find(searchCol < value);
                end

            else

                index = str2double(condition);
                if ~isnan(index) && index >= 1 && index <= activeNwk.np
                    indices = index;
                elseif ~isempty(condition)
                    disp(['Invalid input: ', condition]);
                end
            
            end
        end
    end

    function [inDeg, outDeg] = calculateInOutDegree()
         C1= nwkSim.ConnectivityMx(activeNwk.nf, activeNwk.np, activeNwk.faceMx);
         [inDeg, outDeg] = nwkHelp.getNodeDegrees(activeNwk, C1);
    end

    % Function to close both figures
    function closeBothFig(~, ~)
        delete(fig);
        delete(axesFig);
    end
   
    function reApplyUIOptions()

        if boundingBoxOn.Value && isempty(rendererTable.boxHandle{activeIdx}) || ~boundingBoxOn.Value && ~isempty(rendererTable.boxHandle{activeIdx})
            boundingBoxCb();
        end

        if toggleCylindersView.Value && contains(activeHandle.UserData(1).type, 'graph') || ~toggleCylindersView.Value && strcmp(activeHandle.UserData(1).type, 'cylinders')
            togglePlotCb([], [], []);
        end

        directionsOnCb();
        
        labelsOnCb();

    end

    function resetOnRedraw()
    
        % Disable face or pt selection modes if it is set
        if ptSelect.Value
            ptSelect.Value = false;
            ptSelectCb();
        elseif faceSelect.Value
            faceSelect.Value = false;
            faceSelectCb();
        end

        % if toggleCylindersView.Value
        %     toggleCylindersView.Value = false;
        %     colorbar('off');
        % end


    end    


    function reApplyHighlights()
        try
            if contains(activeHandle.UserData(1).type, 'subgraph')
                reColorGrps();
            elseif strcmp(activeHandle.UserData(1).type, 'graph') || strcmp(activeHandle.UserData(1).type, 'digraph')
    
                % % Prioritising selections over endpoints/endfaces
                if ~isempty(ptEditBox.Value) || ~isempty(faceEditBox.Value) 
                    updateSelections();
                else
                    faceGrpEditCb();
                end
                % 
                % if isfield(activeHandle.UserData, 'groups') && ~isempty(activeHandle.UserData(1).groups)
                %       faceGrpEditCb();
                % elseif  ~isempty(ptEditBox.Value) || ~isempty(faceEditBox.Value)
                %       updateSelections();
                % end
            end
        catch ME
            if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
                disp('Empty graph plot');
            else
                rethrow(ME);
            end
        end
    end

    function color = validateColor(colorName)
        colorName = lower(colorName);
        validColors = {'red', 'blue', 'green', 'cyan', 'magenta', 'yellow', 'black', 'white'};
        if ismember(colorName, validColors)
            color = colorName;
        else
            color = 'black';
        end
    end

    function [grpIds] = selectLoadGrps()

        groupIDs = activeNwk.faceMx(:, 1);
        dia = activeNwk.dia;

        % Choose two groups with largest diameters
        % Compares 25th percentile of each group
        uniqueGroupIDs = unique(groupIDs);
        groupPercentiles = zeros(length(uniqueGroupIDs), 1);
        for i = 1:length(uniqueGroupIDs)
            groupIdx = groupIDs == uniqueGroupIDs(i);
            groupPercentiles(i) = prctile(dia(groupIdx), 50);
        end
        [~, sortedIdx] = sort(groupPercentiles);
        sortedGroupIds = uniqueGroupIDs(sortedIdx);
        grpIds = sortedGroupIds(end:-1:end-1)';

        if size(uniqueGroupIDs, 1) == 2
            grpIds = sortedGroupIds(end)';
        end

        % % Choose two groups with least number of faces
        % uniqueGroupIDs = unique(groupIDs);
        % groupCounts = arrayfun(@(x) sum(groupIDs == x), uniqueGroupIDs);
        % [~, sortedIdx] = sort(groupCounts);
        % smallestGroups = uniqueGroupIDs(sortedIdx(1:2));
        % grpIds = smallestGroups;
    end

    function resetColors(~, ~)

        % Delete existing colors, so new group area is created with predefined colors
        rendererTable.grpColors{activeIdx}([unique(activeNwk.faceMx(:,1))]) = [];
        initGroupBox();
        
        % Apply the new color changes to graph
        faceGrpEditCb();
    end    
 
end