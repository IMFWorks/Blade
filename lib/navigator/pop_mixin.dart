import 'package:blade/container/blade_container.dart';
import 'package:blade/container/blade_page.dart';
import 'package:blade/messenger/nativeEvents/pop_native_page_event.dart';
import 'package:blade/messenger/page_info.dart';
import 'package:blade/navigator/base_navigator.dart';
import '../logger.dart';

mixin PopMixin on BaseNavigator {
  final List<BladeContainer> _pendingPopContainers = <BladeContainer>[];

  void pop<T>({String? id, T? result}) async {
    BladeContainer? container;
    if (id != null) {
      container = containerManager.getContainerById(id);
      if (container == null) {
        return;
      }
    } else {
      container = topContainer;
    }

    if (container != topContainer) {
      return;
    }
    if (container.pages.length > 1) {
      container.pop(result);
    } else {
      _popContainer(container, result as Map<String, dynamic>?);
    }

    Logger.log('pop , id=$id, $container');
  }

  Future<void> popUtil<T extends Object>(String id, [T? result]) async {

  }

  void _popContainer(BladeContainer container, Map<String, dynamic>? result) async {
    Logger.log('_popContainer ,  id=${container.pageInfo.id}');
    containerManager.removeContainer(container);
    _pendingPopContainers.add(container);

    final pageInfo = PageInfo(name: container.pageInfo.name,
        id: container.pageInfo.id,
        arguments:result);
    final popNativePageEvent = PopNativePageEvent(pageInfo);
    eventDispatcher.sendNativeEvent(popNativePageEvent);
  }

  void removeContainer(PageInfo pageInfo) {
    _removeContainer(pageInfo.id, targetContainers: _pendingPopContainers);
    _removeContainer(pageInfo.id, targetContainers: containerManager.containers);
  }

  void removePendingContainerById(String id) {
    _removeContainer(id, targetContainers: _pendingPopContainers);
  }

  void _removeContainer(String id, {required List<BladeContainer> targetContainers}) {
    BladeContainer? removedContainer;
    targetContainers.removeWhere((element) {
      final isSame = element.pageInfo.id == id;
      if (isSame) {
        removedContainer = element;
      }

      return isSame;
    } );

    removedContainer?.entryRemoved();
  }

  BladeContainer? getPendingPopContainer(String id) {
    try {
      return _pendingPopContainers.singleWhere((BladeContainer element) =>
      (element.pageInfo.id == id) ||
          element.pages.any((BladePage<dynamic> element) =>
          element.pageInfo.id == id));
    } catch (e) {
      Logger.logObject(e);
    }
    return null;
  }
}