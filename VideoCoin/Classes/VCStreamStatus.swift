//
// Created by Ryoichiro Oka on 12/15/19.
// Copyright (c) 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation

public enum VCStreamStatus : String, Decodable {
    case STREAM_STATUS_NONE
	case STREAM_STATUS_NEW
	case STREAM_STATUS_PREPARING
	case STREAM_STATUS_PREPARED
    case STREAM_STATUS_PENDING
    case STREAM_STATUS_READY
	case STREAM_STATUS_COMPLETED
	case STREAM_STATUS_FAILED
}
