#if defined(__APPLE__)
    #include <tr1/tuple>
    #define _tuple std::tr1::tuple
#else
    #include <tuple>
    #define _tuple std::tuple
#endif
#include <df/reaction_product_itemst.h>

static const int last_item_type = df::enum_traits<df::item_type>::last_item_value;

typedef _tuple<int,int,int> group_key;

struct item_info {
    df::item *item;
};

struct group_info {
    group_info() : count(0) {};

    df::item_type type;
    int subtype, mat_type, mat_index;
    int count;
    std::string title;
    vector<df::item*> items;
    df::item_flags flags_all, flags_some;

    static struct_identity _identity;    
};

struct type_category {
    type_category() : count(0), busy(0) {};

    int count, busy;
    std::map<group_key, group_info> groups;
    std::vector<group_info*> groups_index;
    
    static struct_identity _identity;    
};

struct itemcache_wrapper {
    type_category cats[last_item_type+1];

    static struct_identity _identity;    
};

itemcache_wrapper itemcache;

static df::reaction_product_itemst *q = NULL;
std::string get_group_title(group_info &group)
{
    if (!q)
        q = df::allocate<df::reaction_product_itemst>();

    q->item_type = group.type;
    q->item_subtype = group.subtype;
    q->mat_type = group.mat_type;
    q->mat_index = group.mat_index;
    q->count = group.count;
    
    std::string tmp;
    q->getDescription(&tmp);

    //TODO: df2utf is required here ?

    tmp[0] = tolower(tmp[0]);
    tmp.resize(tmp.rfind(" ")); //remove " (0%)"

    return tmp;
}

static inline bool item_is_busy(df::item *item)
{
    return item->flags.bits.in_building || item->flags.bits.construction
        || item->flags.bits.dump || item->flags.bits.melt || item->flags.bits.forbid
        || item->flags.bits.rotten || item->flags.bits.spider_web || item->flags.bits.trader;
}

void itemcache_init()
{
    for (int i = 0; i <= last_item_type; i++)
    {
        itemcache.cats[i].groups.clear();
        itemcache.cats[i].groups_index.resize(0);
        itemcache.cats[i].count = 0;
        itemcache.cats[i].busy = 0;
    }

    std::vector<df::item *> &items = world->items.other[items_other_id::IN_PLAY];
    for (auto it = items.begin(); it != items.end(); it++)
    {
        df::item *item = *it;

        auto pos = Items::getPosition(item);
        if (pos.x == -30000)
            continue;

        auto designation = Maps::getTileDesignation(pos);
        if (!designation || designation->bits.hidden)
            continue;

        std::string label = Items::getDescription(item, 0, false);
        
        df::item_type type = item->getType();
        int subtype = item->getSubtype();
        int mat_type = item->getMaterial();
        int mat_index = item->getMaterialIndex();
        int stack = item->getStackSize();
        
        type_category &cat = itemcache.cats[type];

        df::item *container = Items::getContainer(item);
        df::unit *holder = item->flags.bits.in_inventory ? Items::getHolderUnit(item) : NULL;
        if (item_is_busy(item) || (container && item_is_busy(container)) || (holder && !Units::isCitizen(holder)))
            cat.busy += stack;
        else
            cat.count += stack;
        
        group_info &group = cat.groups[group_key(subtype, mat_type, mat_index)];
        if (!group.count)
        {
            group.type = type; group.subtype = subtype; group.mat_type = mat_type; group.mat_index = mat_index;
            cat.groups_index.push_back(&group);
            group.title = get_group_title(group);
            group.flags_all = ~0;
            group.flags_some = 0;
        }

        if (group.items.size())
        {
            int q = item->getQuality();
            bool inserted = false;
            for (auto it2 = group.items.begin(); it2 != group.items.end(); it2++)
            {
                if ((*it2)->getQuality() < q)
                {
                    group.items.insert(it2, item);
                    inserted = true;
                    break;
                }
            }
            if (!inserted)
                group.items.push_back(item);
        }
        else
            group.items.push_back(item);

        group.flags_some.whole |= item->flags.whole;
        group.flags_all.whole &= item->flags.whole;

        group.count += stack;
    }
}

static void itemcache_free()
{
}

static void update_group_flags(group_info *group)
{
    group->flags_all = ~0;
    group->flags_some = 0;

    for (auto it = group->items.begin(); it != group->items.end(); it++)
    {
        df::item *item = *it;

        group->flags_some.whole |= item->flags.whole;
        group->flags_all.whole &= item->flags.whole;
    }    
}

static std::vector<group_info*> *itemcache_search(std::string q)
{
    q = toLower(q);

    std::vector<group_info*> *ret = new std::vector<group_info*>;

    for (int j = 0; j <= last_item_type; j++)
    {
        type_category &cat = itemcache.cats[j];

        for (auto it = cat.groups_index.begin(); it != cat.groups_index.end(); it++)
        {
            group_info *group = *it;
            if (group->title.find(q) != string::npos)
            {
                update_group_flags(group);                
                ret->push_back(group);
            }
        }
    }

    return ret;
}

static itemcache_wrapper* itemcache_get()
{
    return &itemcache;
}

static type_category* itemcache_get_category(int catidx)
{
    type_category &cat = itemcache.cats[catidx];

    for (auto it = cat.groups_index.begin(); it != cat.groups_index.end(); it++)
    {
        group_info *group = *it;
        update_group_flags(group);
    }

    return &cat;
}

#include <DataDefs.h>


#define TID(type) (&df::identity_traits< type >::identity)
#define FLD(mode, name) struct_field_info::mode, #name, offsetof(CUR_STRUCT, name)
#define GFLD(mode, name) struct_field_info::mode, #name, (size_t)&df::global::name
#define METHOD(mode, name) struct_field_info::mode, #name, 0, wrap_function(&CUR_STRUCT::name)
#define FLD_END struct_field_info::END


#define CUR_STRUCT group_info
static const struct_field_info group_info_fields[] = {
    { FLD(PRIMITIVE, title), df::identity_traits<std::string >::get() },
    { FLD(PRIMITIVE, count), TID(int32_t) },
    { FLD(PRIMITIVE, type), df::identity_traits<df::item_type >::get() },
    { FLD(PRIMITIVE, subtype), TID(int32_t) },
    { FLD(PRIMITIVE, mat_type), TID(int32_t) },
    { FLD(PRIMITIVE, mat_index), TID(int32_t) },
    { FLD(STL_VECTOR_PTR, items), df::identity_traits<df::item >::get(), 0, NULL },
    { FLD(SUBSTRUCT, flags_all), TID(df::item_flags) },
    { FLD(SUBSTRUCT, flags_some), TID(df::item_flags) },
    { FLD_END }
};
struct_identity group_info::_identity(sizeof(group_info), &df::allocator_fn<group_info>, NULL, "group_info",NULL,group_info_fields);
#undef CUR_STRUCT


#define CUR_STRUCT type_category
static const struct_field_info type_category_fields[] = {
    { FLD(PRIMITIVE, count), TID(int32_t) },
    { FLD(PRIMITIVE, busy), TID(int32_t) },
    { FLD(STL_VECTOR_PTR, groups_index), df::identity_traits<group_info >::get(), 0, NULL },
    { FLD_END }
};
struct_identity type_category::_identity(sizeof(type_category), &df::allocator_fn<type_category>, NULL, "type_category",NULL,type_category_fields);
#undef CUR_STRUCT


#define CUR_STRUCT itemcache_wrapper
static const struct_field_info itemcache_wrapper_fields[] = {
    { FLD(STATIC_ARRAY, cats), df::identity_traits<type_category >::get(), last_item_type+1, TID(df::item_type) },
    { FLD_END }
};
struct_identity itemcache_wrapper::_identity(sizeof(itemcache_wrapper), &df::allocator_fn<itemcache_wrapper>, NULL, "itemcache_wrapper",NULL,itemcache_wrapper_fields);
#undef CUR_STRUCT
