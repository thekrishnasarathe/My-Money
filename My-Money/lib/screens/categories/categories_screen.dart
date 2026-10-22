import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _State();
}

class _State extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab=TabController(length:2,vsync:this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child:Column(children:[
        const Padding(
          padding: EdgeInsets.fromLTRB(20,16,20,0),
          child: Align(alignment:Alignment.centerLeft,
            child:Text('Categories',style:TextStyle(
              fontSize:24,fontWeight:FontWeight.bold)))),
        const SizedBox(height:12),
        TabBar(controller:_tab,
          indicatorColor:AppTheme.primary,
          labelColor:AppTheme.primary,
          unselectedLabelColor:AppTheme.textSecondary,
          tabs:const[Tab(text:'Expense'),Tab(text:'Income')]),
        Expanded(child:TabBarView(controller:_tab,children:[
          _CatList(type:'Expense',p:p),
          _CatList(type:'Income',p:p),
        ])),
      ])),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: ()=>_showAddSheet(context,p,'Expense'),
        child: const Icon(Icons.add,color:Colors.black)),
    );
  }

  void _showAddSheet(BuildContext ctx,AppProvider p,String type){
    showModalBottomSheet(context:ctx,isScrollControlled:true,
      backgroundColor:Colors.transparent,
      builder:(_)=>_CategorySheet(p:p,
        initialType:_tab.index==0?'Expense':'Income'));
  }
}

class _CatList extends StatelessWidget {
  final String type; final AppProvider p;
  const _CatList({required this.type,required this.p});

  @override
  Widget build(BuildContext context){
    final cats = type=='Expense'?p.expenseCategories():p.incomeCategories();
    if(cats.isEmpty) return const EmptyState(
      icon:Icons.grid_view_outlined,title:'No categories');
    return ListView.builder(
      padding:const EdgeInsets.fromLTRB(16,12,16,80),
      itemCount:cats.length,
      itemBuilder:(_,i){
        final c=cats[i];
        final color=AppTheme.fromHex(c.color);
        return Container(
          margin:const EdgeInsets.only(bottom:8),
          decoration:BoxDecoration(color:AppTheme.cardDark,
            borderRadius:BorderRadius.circular(14)),
          child:ListTile(
            leading:Container(width:42,height:42,
              decoration:BoxDecoration(color:color.withOpacity(0.15),
                borderRadius:BorderRadius.circular(12)),
              child:Icon(categoryIconData(c.icon),color:color,size:20)),
            title:Text(c.name,style:const TextStyle(fontSize:14,
              fontWeight:FontWeight.w500)),
            subtitle:Text(c.isDefault?'Default':'Custom',
              style:const TextStyle(color:AppTheme.textSecondary,fontSize:11)),
            trailing:IconButton(
              icon:const Icon(Icons.edit_outlined,
                color:AppTheme.textSecondary,size:18),
              onPressed:()=>showModalBottomSheet(context:context,
                isScrollControlled:true,backgroundColor:Colors.transparent,
                builder:(_)=>_CategorySheet(p:p,edit:c))),
          ));
      });
  }
}

class _CategorySheet extends StatefulWidget {
  final AppProvider p;
  final AppCategory? edit;
  final String initialType;
  const _CategorySheet({required this.p,this.edit,this.initialType='Expense'});
  @override
  State<_CategorySheet> createState()=>_CSState();
}

class _CSState extends State<_CategorySheet>{
  final _nameCtrl=TextEditingController();
  late String _type,_color,_icon;

  static const _icons=[
    'restaurant','local_cafe','directions_car','local_taxi','local_bar',
    'menu_book','checkroom','movie','local_hospital','bolt','home',
    'shopping_bag','local_gas_station','outdoor_grill','child_care',
    'school','payments','card_giftcard','business','cached','work',
    'family_restroom','account_balance','history','trending_up',
    'category','wallet','star','savings','attach_money',
  ];

  @override
  void initState(){
    super.initState();
    _type=widget.edit?.type??widget.initialType;
    _color=widget.edit?.color??'#00C6A2';
    _icon=widget.edit?.icon??'category';
    if(widget.edit!=null)_nameCtrl.text=widget.edit!.name;
  }
  @override
  void dispose(){_nameCtrl.dispose();super.dispose();}

  @override
  Widget build(BuildContext context){
    return Container(
      decoration:const BoxDecoration(color:AppTheme.cardDark,
        borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
      padding:EdgeInsets.only(
        bottom:MediaQuery.of(context).viewInsets.bottom),
      child:SingleChildScrollView(
        padding:const EdgeInsets.all(20),
        child:Column(mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.start,children:[
          Center(child:Container(width:40,height:4,
            decoration:BoxDecoration(color:AppTheme.divider,
              borderRadius:BorderRadius.circular(2)))),
          const SizedBox(height:16),
          // Icon preview
          Center(child:Container(width:64,height:64,
            decoration:BoxDecoration(
              color:AppTheme.fromHex(_color).withOpacity(0.2),
              borderRadius:BorderRadius.circular(18)),
            child:Icon(categoryIconData(_icon),
              color:AppTheme.fromHex(_color),size:32))),
          const SizedBox(height:16),
          // Type toggle
          Row(children:[
            _TB('Expense',_type=='Expense',AppTheme.expenseRed,
              ()=>setState(()=>_type='Expense')),
            const SizedBox(width:8),
            _TB('Income',_type=='Income',AppTheme.incomeGreen,
              ()=>setState(()=>_type='Income')),
          ]),
          const SizedBox(height:14),
          TextField(controller:_nameCtrl,
            decoration:const InputDecoration(
              hintText:'Category Name',
              prefixIcon:Icon(Icons.label_outline,
                color:AppTheme.textSecondary))),
          const SizedBox(height:16),
          const Text('COLOR',style:TextStyle(color:AppTheme.textSecondary,
            fontSize:11,fontWeight:FontWeight.w600)),
          const SizedBox(height:10),
          ColorPickerRow(selected:_color,
            onSelect:(c)=>setState(()=>_color=c)),
          const SizedBox(height:16),
          const Text('ICON',style:TextStyle(color:AppTheme.textSecondary,
            fontSize:11,fontWeight:FontWeight.w600)),
          const SizedBox(height:10),
          Wrap(spacing:8,runSpacing:8,children:_icons.map((ico){
            final sel=ico==_icon;
            final color=AppTheme.fromHex(_color);
            return GestureDetector(
              onTap:()=>setState(()=>_icon=ico),
              child:Container(width:44,height:44,
                decoration:BoxDecoration(
                  color:sel?color.withOpacity(0.2):AppTheme.cardDark2,
                  borderRadius:BorderRadius.circular(10),
                  border:sel?Border.all(color:color):null),
                child:Icon(categoryIconData(ico),
                  color:sel?color:AppTheme.textSecondary,size:20)));
          }).toList()),
          const SizedBox(height:20),
          Row(children:[
            if(widget.edit!=null&&!widget.edit!.isDefault)...[
              Expanded(child:OutlinedButton(
                onPressed:()async{
                  await widget.p.deleteCategory(widget.edit!.id!);
                  if(mounted)Navigator.pop(context);
                },
                style:OutlinedButton.styleFrom(
                  foregroundColor:AppTheme.expenseRed,
                  side:const BorderSide(color:AppTheme.expenseRed)),
                child:const Text('Delete'))),
              const SizedBox(width:10),
            ],
            Expanded(child:PrimaryButton(
              label:widget.edit!=null
                ?'Update Category':'Create Category',
              onTap:()async{
                if(_nameCtrl.text.trim().isEmpty)return;
                final now=DateTime.now();
                if(widget.edit!=null){
                  await widget.p.updateCategory(widget.edit!.copyWith(
                    name:_nameCtrl.text.trim(),
                    type:_type,color:_color,icon:_icon));
                }else{
                  await widget.p.addCategory(AppCategory(
                    name:_nameCtrl.text.trim(),type:_type,
                    color:_color,icon:_icon,createdAt:now));
                }
                if(mounted)Navigator.pop(context);
              })),
          ]),
          const SizedBox(height:8),
        ]),
      ),
    );
  }
}

Widget _TB(String l,bool a,Color c,VoidCallback t)=>
  Expanded(child:GestureDetector(onTap:t,child:Container(
    padding:const EdgeInsets.symmetric(vertical:10),
    decoration:BoxDecoration(
      color:a?c.withOpacity(0.15):AppTheme.cardDark2,
      borderRadius:BorderRadius.circular(10),
      border:a?Border.all(color:c):null),
    child:Center(child:Text(l,style:TextStyle(
      color:a?c:AppTheme.textSecondary,
      fontWeight:a?FontWeight.bold:FontWeight.normal))))));
