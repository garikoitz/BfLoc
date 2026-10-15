classdef votclocSequence

    properties
        lang        % stimulus langauge
        num_runs    % number of runs in experiment
        stim_onsets % onset times of each stimulus in a run
        stim_names  % sequence of stimulus fildnames
        task_probes % index of stimuli that are task probes
    end

    properties (Hidden)
        stim_set     % stimulus set/s (1 = standard, 2 = alternate, 3 = both)
        task_num     % task number (1 = 1-back, 2 = 2-back, 3 = oddball)
        block_onsets % block onsets relative to beginning of run (seconds)
        block_conds  % block conditions labels
        stim_files   % image numbers available in each category folder (filled by make_runs)
    end

    properties (Constant)
        % tempread design: 8 categories, order must match stim_set1 below
        stim_conds = {'RealWords' 'Faces' 'Hands' 'FalseFonts' 'Scrambled' 'Objects' 'Food' 'Limbs'};
        stim_per_block = 16;   % number of stimuli in a block (16 x 0.5 s = 8 s blocks)
        stim_duty_cycle = 0.5; % duration of stimulus duty cycle (s)
    end

    properties (Constant, Hidden)
        % JP
        % stim_set1 = {'body' 'JP_word1' 'adult' 'JP_FF1' 'JP_CB1'};
        % stim_set2 = {'limb' 'JP_word2' 'child' 'JP_CS1' 'JP_SC1'};
        % EU
        % stim_set1 = {'body' 'EU_word1' 'adult' 'EU_FF1' 'EU_CB1'};
        % stim_set2 = {'limb' 'EU_word2' 'child' 'EU_CS1' 'EU_SC1'};
        % ES
        % stim_set1 = {'bodylimb' '_RW' 'face' 'ES_FF' 'ES_CS' 'ES_SC'};
        % stim_set2 = {'limb' 'ES_word' 'child' 'ES_CS' 'ES_SC'};

        % stim_set1 = {'body' 'chars' 'adult' 'instrument' 'corridor'};
        % stim_set2 = {'limb' 'numbers' 'child' 'car' 'house'};
        % make_orders needs trials_per_cond to be a multiple of num_conds (8 + baseline = 9)
        trials_per_cond = 9;
        probes_per_cond = 2; % task probes per stimulus category per run
        task_names = {'1back' '2back' 'oddball'};
        stim_dir = fullfile(fileparts(fileparts(which(mfilename, 'class'))), 'stimuli');
    end

    properties (Dependent)
        task_name % descriptor for each task number
        run_dur   % run duration (seconds)
        stim_dur  % stimulus duration (seconds)
        isi_dur   % interstimulus interval duration (seconds)
    end

    properties (Dependent, Hidden)
        stim_set1 % dynamically generate stimulus set based on lang
        stim_set2 % dynamically generate stimulus set based on lang
        num_conds % number of conditions in experiment
        run_sets  % stimulus set used in each run

    end

    methods

        % class constructor
        function seq = votclocSequence(lang, stim_set, num_runs, task_num)
            if nargin < 1
                seq.lang = 'ES';
            else
                seq.lang=lang;
            end
            if nargin < 2
                seq.stim_set = 1;
            else
                seq.stim_set = stim_set;
            end
            if nargin < 3
                seq.num_runs = 2;
            else
                seq.num_runs = num_runs;
            end
            if nargin < 4
                seq.task_num = 1;
            else
                seq.task_num = task_num;
            end
        end

        % get name of task
        function task_name = get.task_name(seq)
            task_name = seq.task_names{seq.task_num};
        end

        % get run duration given stimulus duty cycle
        function run_dur = get.run_dur(seq)
            block_dur = seq.stim_per_block * seq.stim_duty_cycle;
            % baseline padding block + all condition blocks + baseline padding block
            blocks_per_run = 1 + seq.num_conds * seq.trials_per_cond + 1;
            run_dur = block_dur * blocks_per_run;
        end

        % get ISI duration given task
        function isi_dur = get.isi_dur(seq)
            if seq.task_num == 3
                isi_dur = 0;
            else
                isi_dur = 0.2;
            end
        end

        % get stimulus duration given ISI
        function stim_dur = get.stim_dur(seq)
            stim_dur = seq.stim_duty_cycle - seq.isi_dur;
        end

        % get number of experimental conditions including baseline
        function num_conds = get.num_conds(seq)
            num_conds = 1 + length(seq.stim_conds);
        end

        % get image sets for each run given selection
        function run_sets = get.run_sets(seq)
            switch seq.stim_set
                case 1
                    run_sets = repmat(seq.stim_set1, seq.num_runs, 1);
                case {2, 3}
                    % no second set of hand/food/object images yet
                    error('The tempread design only has stim_set 1.');
                otherwise
                    error('Invalid stim_set argument.');
            end
        end

        % dynamically generate stimulus set based on lang
        % order matches stim_conds
        function stim_set1 = get.stim_set1(seq)
            stim_set1= {...
                sprintf('%s_RW1',seq.lang) ...
                'face1' ...
                'hand' ...
                sprintf('%s_FF1',seq.lang) ...
                sprintf('%s_SC1',seq.lang) ...
                'instrument' ...
                'dessert' ...
                'bodylimb1' ...
                };
        end
        function stim_set2 = get.stim_set2(seq)
            stim_set2= {...
                'bodylimb2' ...
                sprintf('%s_RW2',seq.lang) ...
                'face2' ...
                sprintf('%s_FF2',seq.lang) ...
                sprintf('%s_CS2',seq.lang) ...
                sprintf('%s_SC2',seq.lang) ...
                };
        end

        % list the image numbers that exist in a category folder
        % (files are named <folder>-N.jpg; numbers need not be contiguous)
        function nums = get_stim_nums(seq, cat)
            files = dir(fullfile(seq.stim_dir, cat, [cat '-*.jpg']));
            tokens = regexp({files.name}, ['^' cat '-(\d+)\.jpg$'], 'tokens', 'once');
            tokens = tokens(~cellfun(@isempty, tokens));
            nums = sort(cellfun(@(X) str2double(X{1}), tokens));
            if isempty(nums)
                error('No images found for category %s in %s', cat, fullfile(seq.stim_dir, cat));
            end
        end

        % generate randomized stimulus sequences and insert task probes
        function seq = make_runs(seq)
            % calculate number of images needed from each category
            [unique_cats, ~, idxs] = unique(seq.run_sets(:));
            unique_cats = unique_cats';
            cnts = accumarray(idxs(:), 1, [], @sum)';
            stim_per_cat = cnts * seq.stim_per_block * seq.trials_per_cond;
            % randomize the order of stimuli minimizing image repetition:
            % cycle through every image of a category before reusing any,
            % and keep each image at least stim_per_block positions away
            % from its previous use so no image repeats within a block
            stim_nums = cell(1, length(unique_cats));
            seq.stim_files = struct();
            for cc = 1:length(unique_cats)
                avail = get_stim_nums(seq, unique_cats{cc});
                seq.stim_files.(matlab.lang.makeValidName(unique_cats{cc})) = avail;
                gap = min(seq.stim_per_block - 1, floor(numel(avail) / 2));
                nums = avail(randperm(numel(avail)));
                while numel(nums) < stim_per_cat(cc)
                    cycle = avail(randperm(numel(avail)));
                    recent = ismember(cycle, nums(end - gap + 1:end));
                    ok = cycle(~recent);
                    cycle = [ok(1:gap) shuffle([ok(gap + 1:end) cycle(recent)])];
                    nums = [nums cycle];
                end
                stim_nums{cc} = nums(1:stim_per_cat(cc));
            end

            % get order of conditions in each run with padding blocks
            % trials_per_cond
            block_conds = make_orders(seq.num_conds, seq.trials_per_cond, seq.num_runs);
            block_conds = [zeros(1, seq.num_runs); block_conds; zeros(1, seq.num_runs)];
            block_dur = seq.stim_per_block * seq.stim_duty_cycle;
            block_onsets = repmat(0:block_dur:seq.run_dur - block_dur, seq.num_runs, 1)';
            % generate sequence of stimulus filenames for each run
            % trials_per_cond
            stim_mat = cell(seq.stim_per_block, seq.num_conds *seq.trials_per_cond + 2, seq.num_runs);
            for rr = 1:seq.num_runs
                cat_list = ['baseline' seq.run_sets(rr, :)];
                cat_seq = cat_list(block_conds(:, rr) + 1);
                stim_mat(:, :, rr) = repmat(cat_seq, seq.stim_per_block, 1);
            end
            stim_cat_list = reshape(stim_mat, [], 1);
            stim_num_list = zeros(size(stim_cat_list));
            for cc = 1:length(unique_cats)
                cat_idxs = find(strcmp(unique_cats{cc}, stim_mat));
                stim_num_list(cat_idxs) = stim_nums{cc};
            end
            stim_num_list = num2cell(stim_num_list);
            stim_num_list = cellfun(@(X) ['-' num2str(X) '.jpg'], stim_num_list, 'uni', false);
            stim_num_list = strrep(stim_num_list, '-0.jpg', '');
            stim_list = cellfun(@(X, Y) [X Y], stim_cat_list, stim_num_list, 'uni', false);
            % insert task probes: probes_per_cond randomly-selected blocks
            % of every stimulus category in each run, one probe per block
            num_stim_conds = length(seq.stim_conds);
            probes_per_run = seq.probes_per_cond * num_stim_conds;
            if seq.task_num == 2
                probe_pos = randi(seq.stim_per_block - 3, [probes_per_run seq.num_runs]) + 2;
            else
                probe_pos = randi(seq.stim_per_block - 2, [probes_per_run seq.num_runs ]) + 1;
            end
            % trials_per_cond
            probe_stim_mat = zeros(seq.stim_per_block, seq.num_conds*seq.trials_per_cond + 2, seq.num_runs);
            for rr = 1:seq.num_runs
                probe_block_idxs = [];
                for cc = 1:num_stim_conds
                    cond_block_idxs = shuffle(find(block_conds(:, rr) == cc));
                    probe_block_idxs = [probe_block_idxs; cond_block_idxs(1:seq.probes_per_cond)];
                end
                xi = probe_pos(:, rr);
                yi = sort(probe_block_idxs);
                zi = repmat(rr, probes_per_run, 1);
                run_probe_idxs = sub2ind(size(probe_stim_mat), xi, yi, zi);
                probe_stim_mat(run_probe_idxs) = 1;
            end
            probe_stim_idxs = find(probe_stim_mat);
            if seq.task_num == 1
                probe_stim_names = stim_list(probe_stim_idxs - 1);
            elseif seq.task_num == 2
                probe_stim_names = stim_list(probe_stim_idxs - 2);
            else
                scrambled_nums = get_stim_nums(seq, 'scrambled');
                oddball_nums = num2cell(scrambled_nums(randi(numel(scrambled_nums), probes_per_run * seq.num_runs, 1)));
                probe_stim_names = cellfun(@(X) ['scrambled-' num2str(X) '.jpg'], oddball_nums, 'uni', false);
            end
            stim_list(probe_stim_idxs) = probe_stim_names;
            % here is reshape the sequence into different runs
            stim_names = reshape(stim_list', [], seq.num_runs);
            stim_onsets = repmat(0:seq.stim_duty_cycle:seq.run_dur - seq.stim_duty_cycle, seq.num_runs, 1)';
            task_probes = reshape(probe_stim_mat, [], seq.num_runs);
            % store stimulus sequence parameters
            seq.block_onsets = block_onsets;
            seq.block_conds = block_conds;
            seq.stim_onsets = stim_onsets;
            seq.stim_names = stim_names;
            seq.task_probes = task_probes;
        end

    end

end
