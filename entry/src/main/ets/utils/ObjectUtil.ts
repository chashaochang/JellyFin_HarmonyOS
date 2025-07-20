export class ObjectUtil {
  static Assign<T extends {}, U>(target: T, source: U): T & U {
    return Object.assign(target, source);
  }
}
