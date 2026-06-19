import '../models/pictogram.dart';

class PictogramRepository {
  List<Pictogram> getDefaultPictograms() {
    return const [
      Pictogram(
        id: 'quiero',
        text: 'Quiero',
        imagePath: '',
        categoryId: 'basico',
      ),
      Pictogram(id: 'agua', text: 'Agua', imagePath: '', categoryId: 'basico'),
      Pictogram(
        id: 'comer',
        text: 'Comer',
        imagePath: '',
        categoryId: 'basico',
      ),
      Pictogram(id: 'bano', text: 'Baño', imagePath: '', categoryId: 'basico'),
      Pictogram(id: 'si', text: 'Sí', imagePath: '', categoryId: 'basico'),
      Pictogram(id: 'no', text: 'No', imagePath: '', categoryId: 'basico'),
    ];
  }
}
