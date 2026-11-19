function plotCongestionSnapshot(time_min_vec)
% plotCongestionSnapshot
% -------------------------------------------------------------
% Plot congestion snapshots of the road network at specified times.
%
% INPUT:
%   time_min_vec : vector containing the requested times [min]
%
% Example:
%   plotCongestionSnapshot([60 90 120])
%
% Required files:
%   links.csv
%   nodes.csv
%   occupancy.csv
% -------------------------------------------------------------

    %% Read data
    links = readmatrix('links.csv');
    nodes = readmatrix('nodes.csv');
    occupancy_raw = readmatrix('occupancy.csv');

    links = links(~isnan(links(:,1)), :);
    nodes = nodes(~isnan(nodes(:,1)), :);

    %% Network information
    linkID    = links(:,1);
    startNode = links(:,4);
    endNode   = links(:,5);

    nodeID = nodes(:,1);
    nodeX  = nodes(:,2);
    nodeY  = nodes(:,3);

    %% Occupancy data
    occupancyLinkID = occupancy_raw(1,2:end);
    time_sec        = occupancy_raw(2:end,1);
    occupancy       = occupancy_raw(2:end,2:end);

    %% Match occupancy columns with links.csv
    [foundLinks, occupancyColumn] = ismember(linkID, occupancyLinkID);

    if ~all(foundLinks)
        error('Some links in links.csv could not be found in occupancy.csv.');
    end

    occupancy = occupancy(:, occupancyColumn);

    %% Find coordinates of start and end nodes
    [foundStart, startIndex] = ismember(startNode, nodeID);
    [foundEnd, endIndex]     = ismember(endNode, nodeID);

    if ~all(foundStart) || ~all(foundEnd)
        error('Some nodes referenced in links.csv could not be found in nodes.csv.');
    end

    xStart = nodeX(startIndex);
    yStart = nodeY(startIndex);

    xEnd = nodeX(endIndex);
    yEnd = nodeY(endIndex);

    %% Determine tiled layout
    nPlots = length(time_min_vec);

    if nPlots <= 3
        nRows = 1;
        nCols = nPlots;
    else
        nRows = floor(sqrt(nPlots));
        nCols = ceil(nPlots/nRows);
    end

    %% Create figure
    figure('Color','w');

    tl = tiledlayout(nRows,nCols, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    %% Grayscale colormap
    cmap = flipud(gray(256));

    %% Plot snapshots
    for tt = 1:nPlots

        time_min = time_min_vec(tt);
        target_time_sec = time_min * 60;

        row = find(time_sec == target_time_sec,1);

        if isempty(row)
            warning('No measurement found at t = %.1f min.',time_min);
            continue;
        end

        occupancy_vec = occupancy(row,:);
        occupancy_vec = max(0,min(100,occupancy_vec));

        ax = nexttile;
        hold(ax,'on');

        % Set color mapping explicitly for this axes
        colormap(ax,cmap);
        clim(ax,[0 100]);

        %% Plot road links
        for i = 1:length(linkID)

            grayValue = 1 - occupancy_vec(i)/100;

            plot(ax, ...
                [xStart(i) xEnd(i)], ...
                [yStart(i) yEnd(i)], ...
                'Color',[grayValue grayValue grayValue], ...
                'LineWidth',1.5);
        end

        % Invisible object used to establish color mapping
        scatter(ax, ...
            [xStart(1) xStart(1)], ...
            [yStart(1) yStart(1)], ...
            1,[0 100], ...
            'filled', ...
            'Visible','off');

        axis(ax,'equal');
        axis(ax,'tight');
        axis(ax,'off');

        title(ax,sprintf('t = %g min',time_min), ...
            'FontWeight','bold');

        hold(ax,'off');
    end

    %% Shared colorbar
    % Attach it to the last axes, but place it beside the tiled layout
    cb = colorbar(ax);
    cb.Layout.Tile = 'east';

    cb.Label.String = 'Occupancy (%)';
    cb.Ticks = [0 20 40 60 80 100];

    title(tl,'Network Congestion', ...
        'FontWeight','bold');

end