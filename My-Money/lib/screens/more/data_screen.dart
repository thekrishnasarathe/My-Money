import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/theme.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:AppTheme.bgDark,
      appBar:AppBar(title:const Text('Data')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        _Section('EXPORT',[
          _Item(context,Icons.table_chart_outlined,'Export CSV',
            'Share transactions as spreadsheet',
            ()=>_msg(context,'Export CSV — coming soon')),
          _Item(context,Icons.download_outlined,'Export JSON Backup',
            'Full backup of all your data',
            ()=>_msg(context,'Export JSON — coming soon')),
          _Item(context,Icons.picture_as_pdf_outlined,'Export PDF',
            'Generate PDF report',
            ()=>_msg(context,'Export PDF — coming soon')),
        ]),
        const SizedBox(height:16),
        _Section('IMPORT',[
          _Item(context,Icons.upload_outlined,'Import JSON Backup',
            'Restore from a previous backup',
            ()=>_msg(context,'Import JSON — coming soon')),
          _Item(context,Icons.upload_file_outlined,'Import CSV',
            'Import transactions from CSV',
            ()=>_msg(context,'Import CSV — coming soon')),
        ]),
        const SizedBox(height:16),
        _Section('MANAGE',[
          _Item(context,Icons.add_circle_outline,'Add Missing Categories',
            'Add newly available default categories',
            ()async{
              final p=context.read<AppProvider>();
              await p.addMissingDefaultCategories();
              _msg(context,'Default categories updated');
            }),
        ]),
      ]));
  }

  void _msg(BuildContext ctx,String m)=>ScaffoldMessenger.of(ctx)
    .showSnackBar(SnackBar(content:Text(m)));
}

Widget _Section(String title,List<Widget> items)=>Column(
  crossAxisAlignment:CrossAxisAlignment.start,children:[
  Text(title,style:const TextStyle(color:AppTheme.textSecondary,
    fontSize:11,fontWeight:FontWeight.w600)),
  const SizedBox(height:8),
  Container(decoration:BoxDecoration(color:AppTheme.cardDark,
    borderRadius:BorderRadius.circular(14)),
  child:Column(children:items.asMap().entries.map((e)=>Column(children:[
    e.value,
    if(e.key<items.length-1)
      const Divider(indent:60,endIndent:16,height:1,color:AppTheme.divider),
  ])).toList())),
]);

Widget _Item(BuildContext ctx,IconData icon,String title,
  String sub,VoidCallback onTap)=>ListTile(
  leading:Container(width:38,height:38,
    decoration:BoxDecoration(color:AppTheme.primary.withOpacity(0.1),
      borderRadius:BorderRadius.circular(10)),
    child:Icon(icon,color:AppTheme.primary,size:20)),
  title:Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w500)),
  subtitle:Text(sub,style:const TextStyle(
    color:AppTheme.textSecondary,fontSize:11)),
  trailing:const Icon(Icons.chevron_right,color:AppTheme.textSecondary,size:18),
  onTap:onTap);
