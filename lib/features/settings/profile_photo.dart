part of '../../main.dart';

class AccountProfilePhoto extends StatefulWidget {
  final String userId;
  final String name;

  const AccountProfilePhoto({
    required this.userId,
    required this.name,
    super.key,
  });

  @override
  State<AccountProfilePhoto> createState() => _AccountProfilePhotoState();
}

class _AccountProfilePhotoState extends State<AccountProfilePhoto> {
  bool busy = false;

  late final DocumentReference<RowData> photoRef;

  late final Stream<DocumentSnapshot<RowData>> photoStream;

  @override
  void initState() {
    super.initState();

    photoRef = db.collection('profilePhotos').doc(widget.userId);

    photoStream = photoRef.snapshots();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> selectPhoto() async {
    if (busy) return;

    setState(() => busy = true);

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 512,
        maxHeight: 512,
        requestFullMetadata: false,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Unable to read the selected image.');
      }

      if (bytes.length > 300 * 1024) {
        throw Exception(
          'The image is too large. Select a smaller image.',
        );
      }

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Profile photo preview'),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              bytes,
              width: 240,
              height: 240,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('Unable to preview image.'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save photo'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await photoRef.set({
        'bytes': Blob(bytes),
      });

      showMessage('Profile photo updated successfully.');
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> removePhoto() async {
    if (busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'Your profile photo will be removed and '
          'replaced with your initial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || busy) return;

    setState(() => busy = true);

    try {
      await photoRef.delete();

      showMessage('Profile photo removed.');
    } catch (error) {
      showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Widget defaultAvatar() {
    final name = widget.name.trim();

    return CircleAvatar(
      radius: 54,
      backgroundColor: ink.withAlpha(25),
      foregroundColor: ink,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget avatar(Blob? photo) {
    if (photo == null) {
      return defaultAvatar();
    }

    return ClipOval(
      child: Image.memory(
        photo.bytes,
        width: 108,
        height: 108,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => defaultAvatar(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: photoStream,
      builder: (context, snapshot) {
        final value = snapshot.data?.data()?['bytes'];

        final photo = value is Blob ? value : null;

        final ready = snapshot.hasData && !snapshot.hasError;

        return Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                avatar(photo),
                Material(
                  color: ink,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Choose profile photo',
                    onPressed: busy || !ready ? null : selectPhoto,
                    color: Colors.white,
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (snapshot.hasError)
              const Text(
                'Unable to load profile photo.',
              ),
            if (!snapshot.hasData && !snapshot.hasError)
              const LinearProgressIndicator(),
            if (ready)
              TextButton.icon(
                onPressed: busy ? null : selectPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  photo == null ? 'Add profile photo' : 'Change profile photo',
                ),
              ),
            if (ready && photo != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                onPressed: busy ? null : removePhoto,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove photo'),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
          ],
        );
      },
    );
  }
}
