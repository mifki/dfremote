var byline = require('byline');
var fs = require('fs');
var path = require('path');
var glob = require("glob");
var async = require('async');
var msgpack = require("msgpack-lite");

var rawpath = process.argv[2] || 'raw';
var initpath = process.argv[3] || 'init/phoebus_nott';

var data = {
    creatures:{},
    inorganics:{},
    tools:{},
    plants:{},
    track:[],
    tracki:[],
    ramp:[],
    rampi:[],
    tree:[],
};
var last = {};

RegExp.prototype.execAll = function(string) {
    var match = null;
    var matches = new Array();
    while (match = this.exec(string)) {
        var matchArray = [];
        for (i in match) {
            if (parseInt(i) == i) {
                matchArray.push(match[i]);
            }
        }
        matches.push(matchArray);
    }
    return matches;
}

String.prototype.hashCode = function(){
    var hash = 0;
    if (this.length == 0) return hash;
    for (i = 0; i < this.length; i++) {
        char = this.charCodeAt(i);
        hash = ((hash<<5)-hash)+char;
        hash = hash & hash; // Convert to 32bit integer
    }
    return hash;
}

glob(rawpath+"/objects/*.txt", function(err, files) {
    async.eachSeries(files, function(fp, next) {
        if (/language_/.test(fp))
            return next();

        last = {};
        processFile(fp, next);
    }, function(err) {
        last = {d_init:true};
        processFile(initpath+'/d_init.txt', function(){
            var json = JSON.stringify(data);
            var mp = msgpack.encode(data);
            console.log(json.toString());            
        });
    });
});


function processFile(fp, cb) {
    var stream = byline(fs.createReadStream(fp, { encoding: 'utf8' }));
    stream.on('data', function(line) {
        if (!/^\s*\[/.test(line))
            return;

        var ms = /\s*\[([^\]]+)\]/g.execAll(line);
        ms.forEach(function(m) {
            var body = m[1];
            var tokens = body.split(':');
            processLine(tokens);
        });
    });


    stream.on('end', function() {
        cb();
    });  
}

function ensure(type, id) {
    var t = data[type][id];
    if (!t)
        t = data[type][id] = {};

    return t;    
}

function ensureLast() {
    var ks = Object.keys(last);
    var k = ks[0];

    return ensure(k+'s', last[k]);
}

function tilenum(t) {
    if (/'.'/.test(t))
        return t.substr(1,1).charCodeAt(0);
    else
        return +t;
}

var track_tile_tags = [ 'N', 'S', 'E', 'W', 'NS', 'NE', 'NW', 'SE', 'SW', 'EW', 'NSE', 'NSW', 'NEW', 'SEW', 'NSEW' ];

var tree_tile_tags = {
TREE_ROOT_SLOPING:0,
TREE_TRUNK_SLOPING:3,
TREE_ROOT_SLOPING_DEAD:43,
TREE_TRUNK_SLOPING_DEAD:46,
TREE_ROOTS:1,
TREE_ROOTS_DEAD:44,
TREE_BRANCHES:27,
TREE_BRANCHES_DEAD:70,
TREE_SMOOTH_BRANCHES:102,
TREE_SMOOTH_BRANCHES_DEAD:103,
TREE_TRUNK_PILLAR:2,
TREE_TRUNK_PILLAR_DEAD:45,
TREE_CAP_PILLAR:30,
TREE_CAP_PILLAR_DEAD:73,
TREE_TRUNK_N:4,
TREE_TRUNK_S:5,
TREE_TRUNK_N_DEAD:47,
TREE_TRUNK_S_DEAD:48,
TREE_TRUNK_EW:91,
TREE_TRUNK_EW_DEAD:99,
TREE_CAP_WALL_N:31,
TREE_CAP_WALL_S:32,
TREE_CAP_WALL_N_DEAD:74,
TREE_CAP_WALL_S_DEAD:75,
TREE_TRUNK_E:6,
TREE_TRUNK_W:7,
TREE_TRUNK_E_DEAD:49,
TREE_TRUNK_W_DEAD:50,
TREE_TRUNK_NS:90,
TREE_TRUNK_NS_DEAD:98,
TREE_CAP_WALL_E:33,
TREE_CAP_WALL_W:34,
TREE_CAP_WALL_E_DEAD:76,
TREE_CAP_WALL_W_DEAD:77,
TREE_TRUNK_NW:8,
TREE_CAP_WALL_NW:35,
TREE_TRUNK_NW_DEAD:51,
TREE_CAP_WALL_NW_DEAD:78,
TREE_TRUNK_NE:9,
TREE_CAP_WALL_NE:36,
TREE_TRUNK_NE_DEAD:52,
TREE_CAP_WALL_NE_DEAD:79,
TREE_TRUNK_SW:10,
TREE_CAP_WALL_SW:37,
TREE_TRUNK_SW_DEAD:53,
TREE_CAP_WALL_SW_DEAD:80,
TREE_TRUNK_SE:11,
TREE_CAP_WALL_SE:38,
TREE_TRUNK_SE_DEAD:54,
TREE_CAP_WALL_SE_DEAD:81,
TREE_TRUNK_NSE:86,
TREE_TRUNK_NSE_DEAD:94,
TREE_TRUNK_NSW:87,
TREE_TRUNK_NSW_DEAD:95,
TREE_TRUNK_NEW:88,
TREE_TRUNK_NEW_DEAD:96,
TREE_TRUNK_SEW:89,
TREE_TRUNK_SEW_DEAD:97,
TREE_TRUNK_NSEW:92,
TREE_TRUNK_NSEW_DEAD:100,
TREE_TRUNK_BRANCH_N:12,
TREE_TRUNK_BRANCH_N_DEAD:55,
TREE_TRUNK_BRANCH_S:13,
TREE_TRUNK_BRANCH_S_DEAD:56,
TREE_TRUNK_BRANCH_E:14,
TREE_TRUNK_BRANCH_E_DEAD:57,
TREE_TRUNK_BRANCH_W:15,
TREE_TRUNK_BRANCH_W_DEAD:58,
TREE_BRANCH_NS:16,
TREE_BRANCH_NS_DEAD:59,
TREE_BRANCH_EW:17,
TREE_BRANCH_EW_DEAD:60,
TREE_BRANCH_NW:18,
TREE_BRANCH_NW_DEAD:61,
TREE_BRANCH_NE:19,
TREE_BRANCH_NE_DEAD:62,
TREE_BRANCH_SW:20,
TREE_BRANCH_SW_DEAD:63,
TREE_BRANCH_SE:21,
TREE_BRANCH_SE_DEAD:64,
TREE_BRANCH_NSE:22,
TREE_BRANCH_NSE_DEAD:65,
TREE_BRANCH_NSW:23,
TREE_BRANCH_NSW_DEAD:66,
TREE_BRANCH_NEW:24,
TREE_BRANCH_NEW_DEAD:67,
TREE_BRANCH_SEW:25,
TREE_BRANCH_SEW_DEAD:68,
TREE_BRANCH_NSEW:26,
TREE_BRANCH_NSEW_DEAD:69,
TREE_TWIGS:28,
TREE_TWIGS_DEAD:71,
TREE_CAP_RAMP:29,
TREE_CAP_RAMP_DEAD:72,
TREE_CAP_FLOOR1:39,
TREE_CAP_FLOOR2:40,
TREE_CAP_FLOOR1_DEAD:82,
TREE_CAP_FLOOR2_DEAD:83,
TREE_CAP_FLOOR3:41,
TREE_CAP_FLOOR4:42,
TREE_CAP_FLOOR3_DEAD:84,
TREE_CAP_FLOOR4_DEAD:85,
TREE_TRUNK_INTERIOR:93,
TREE_TRUNK_INTERIOR_DEAD:101,    
};

function processLine(params) {
    var tag = params.shift();

    // Top level
    if (tag == 'CREATURE') {
        last = {creature:params[0]};
        return;
    }

    if (tag == 'INORGANIC') {
        last = {inorganic:params[0]};
        return;
    }

    if (tag == 'ITEM_TOOL') {
        last = {tool:params[0]};
        return;
    }

    if (tag == 'PLANT') {
        last = {plant:params[0]};
        return;
    }


    // Creatures
    //TODO: caste tiles !!!
    if (tag == 'CREATURE_TILE' && last.creature) {        
        ensureLast().t = tilenum(params[0]);
        return;
    }

    if (tag == 'ALTTILE' && last.creature) {        
        ensureLast().a = tilenum(params[0]);
        return;
    }

    if (tag == 'CREATURE_SOLDIER_TILE' && last.creature) {        
        ensureLast().s = tilenum(params[0]);
        return;
    }

    if (tag == 'SOLDIER_ALTTILE' && last.creature) {        
        ensureLast().o = tilenum(params[0]);
        return;
    }

    if (tag == 'GLOWTILE' && last.creature) {        
        ensureLast().g = tilenum(params[0]);
        return;
    }

    // Inorganics
    if (tag == 'TILE' && last.inorganic) {
        var t = tilenum(params[0]);
        if (t != 219)
            ensureLast().t = t;
        return;
    }

    if (tag == 'ITEM_SYMBOL' && last.inorganic) {
        var t = tilenum(params[0]);
        if (t != 7)
            ensureLast().s = t;
        return;
    }


    if (tag == 'TILE' && last.tool) {
        ensureLast().t = tilenum(params[0]);
        return;
    }


    // Plants
    //TODO: shrub_color / dead_shrub_color / SAPLING_COLOR / DEAD_SAPLING_COLOR
    if (tag == 'PICKED_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 231)
            ensureLast().p = t;
        return;
    }

    if (tag == 'DEAD_PICKED_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 169)
            ensureLast().dp = t;
        return;
    }

    if (tag == 'SHRUB_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 34)
            ensureLast().s = t;
        return;
    }

    if (tag == 'DEAD_SHRUB_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 34)
            ensureLast().ds = t;
        return;
    }

    if (tag == 'TREE_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 24)
            ensureLast().t = t;
        return;
    }

    if (tag == 'DEAD_TREE_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 198)
            ensureLast().dt = t;
        return;
    }

    if (tag == 'SAPLING_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 231)
            ensureLast().a = t;
        return;
    }

    if (tag == 'DEAD_SAPLING_TILE' && last.plant) {
        var t = tilenum(params[0]);
        if (t != 231)
            ensureLast().da = t;
        return;
    }    

    // Plants - growths
    if (tag == 'GROWTH' && last.plant) {
        var p = ensureLast();
        var g = p.g;
        if (!g) g = p.g = {};
        last.growth = params[0];
        p.g[last.growth] = [];
        return;
    }

    if (tag == 'GROWTH_PRINT' && last.growth) {
        params[0] = tilenum(params[0]);
        params[1] = tilenum(params[1]);
        params[2] = +params[2];
        params[3] = +params[3];
        params[4] = +params[4];
        if (params.length == 6 && params[5] == 'NONE') {
            params[5] = params[6] = -1;
            params[7] = 0;
        }
        else if (params.length == 7) {
            if (params[5] == 'ALL') {
                var p = +params[6];
                params[5] = params[6] = -1;
                params[7] = p;
            } else {
                params[5] = params[6] = -1;
                params[7] = 0;
            }
        } else if (params.length == 8) {
            params[5] = +params[5];
            params[6] = +params[6];            
            params[7] = +params[7];
        } else {
            console.log(params);
            return;
        }

        ensureLast().g[last.growth].push(params);
    }


    // Plants - grass
    //TODO: GRASS_COLORS
    if (tag == 'GRASS_TILES' && last.plant) {
        for (var i in params)
            params[i] = tilenum(params[i]);
        ensureLast().r = params;
        return;
    }    

    if (tag == 'ALT_GRASS_TILES' && last.plant) {
        for (var i in params)
            params[i] = tilenum(params[i]);
        ensureLast().ar = params;
        return;
    }    

    if (tag == 'ALT_PERIOD' && last.plant) {
        for (var i in params)
            params[i] = +params[i];
        ensureLast().ap = params;
        return;
    }


    // d_init
    if (tag == 'SKY' && last.d_init) {
        data.sky = params;
        return;
    }
    if (tag == 'CHASM' && last.d_init) {
        data.chasm = params;
        return;
    }
    if (tag == 'PILLAR_TILE' && last.d_init) {
        data.pillar = tilenum(params[0]);
        return;
    }

    // d_init - track tiles
    if (/^TRACK_[^_]+$/.test(tag) && last.d_init) {
        var i = track_tile_tags.indexOf(tag.substr(6));
        if (i >= 0) {
            if (params[0].substr(-1) == 'I') {
                params[0] = params[0].substr(0,params[0].length-1);
                data.tracki[i] = 1;
            } else
                data.tracki[i] = 0;
            data.track[i] = ''+tilenum(params[0]);
        }
        return;
    }
    if (/^TRACK_RAMP_[^_]+$/.test(tag) && last.d_init) {
        var i = track_tile_tags.indexOf(tag.substr(11));
        if (i >= 0) {
            if (params[0].substr(-1) == 'I') {
                params[0] = params[0].substr(0,params[0].length-1);
                data.rampi[i] = 1;
            } else
                data.rampi[i] = 0;
            data.ramp[i] = tilenum(params[0]);
        }
        return;
    }

    // d_init - tree tiles
    if (/^TREE_/.test(tag) && last.d_init) {
        var i = tree_tile_tags[tag];
        if (i >= 0)
            data.tree[i] = tilenum(params[0]);
    }
}